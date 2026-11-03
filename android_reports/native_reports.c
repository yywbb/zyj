#define _GNU_SOURCE
#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdint.h>
#include <string.h>
#include <time.h>
#if defined(__APPLE__)
#include <sys/ucontext.h>
#else
#include <ucontext.h>
#endif
#include <unistd.h>
#ifndef REPORT_TEST
#include <jni.h>
#endif

static int crash_fd = -1;
static size_t written;
static volatile sig_atomic_t handling;
static const int signals[] = {SIGSEGV, SIGABRT, SIGBUS, SIGILL, SIGFPE, SIGTRAP};
static struct sigaction previous[sizeof(signals) / sizeof(signals[0])];
static __thread unsigned char alternate_stack[65536];

static void emit(const char *text, size_t size) {
    if (written + size > 48000) return;
    while (size) {
        ssize_t count = write(crash_fd, text, size);
        if (count < 0 && errno == EINTR) continue;
        if (count <= 0) return;
        written += (size_t)count;
        text += count;
        size -= (size_t)count;
    }
}

static void literal(const char *text) { emit(text, strlen(text)); }

static void number(const char *name, uint64_t value, unsigned base) {
    char buffer[32];
    size_t length = 0;
    do { buffer[length++] = "0123456789abcdef"[value % base]; value /= base; } while (value);
    literal(name);
    while (length) emit(&buffer[--length], 1);
    literal("\n");
}

/* 只写可执行so的地址/偏移/文件名，不读栈内存、寄存器指向的内容或任意文件。 */
static void image(char *line, size_t length) {
    size_t range = 0, permissions, offset, end, name = 0;
    while (range < length && line[range] != ' ') range++;
    permissions = range;
    while (permissions < length && line[permissions] == ' ') permissions++;
    if (permissions + 4 >= length || line[permissions + 2] != 'x') return;
    offset = permissions + 4;
    while (offset < length && line[offset] == ' ') offset++;
    end = offset;
    while (end < length && line[end] != ' ') end++;
    for (size_t i = end; i < length; i++) if (line[i] == '/') name = i + 1;
    if (!name || length - name < 4 || length - name > 120 || memcmp(line + length - 3, ".so", 3)) return;
    for (size_t i = name; i < length; i++) {
        char c = line[i];
        if (!((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9')
                || c == '_' || c == '.' || c == '+' || c == '-')) return;
    }
    literal("image="); emit(line, range);
    literal(" offset="); emit(line + offset, end - offset);
    literal(" name="); emit(line + name, length - name); literal("\n");
}

static void images(void) {
    int fd = open("/proc/self/maps", O_RDONLY | O_CLOEXEC);
    if (fd < 0) return;
    char input[1024], line[1024];
    size_t length = 0;
    int overflow = 0;
    ssize_t count;
    while ((count = read(fd, input, sizeof(input))) > 0 && written < 46000) {
        for (ssize_t i = 0; i < count; i++) {
            if (input[i] == '\n') {
                if (!overflow) image(line, length);
                length = 0; overflow = 0;
            } else if (length < sizeof(line)) line[length++] = input[i];
            else overflow = 1;
        }
    }
    close(fd);
}

static void crash(int sig, siginfo_t *info, void *context) {
    if (!__sync_lock_test_and_set(&handling, 1)) {
        number("signal=", (uint64_t)sig, 10);
        int64_t code = info ? info->si_code : 0;
        if (code < 0) { literal("code=-"); number("", (uint64_t)-code, 10); }
        else number("code=", (uint64_t)code, 10);
        uintptr_t pc = 0, lr = 0;
#if defined(__ANDROID__) && defined(__aarch64__)
        ucontext_t *state = context;
        pc = state->uc_mcontext.pc; lr = state->uc_mcontext.regs[30];
#elif defined(__ANDROID__) && defined(__arm__)
        ucontext_t *state = context;
        pc = state->uc_mcontext.arm_pc; lr = state->uc_mcontext.arm_lr;
#elif defined(__APPLE__) && defined(__aarch64__)
        ucontext_t *state = context;
        pc = state->uc_mcontext->__ss.__pc; lr = state->uc_mcontext->__ss.__lr;
#else
        (void)context;
#endif
        number("pc=0x", pc, 16); number("lr=0x", lr, 16);
        struct timespec now = {0};
        clock_gettime(CLOCK_REALTIME, &now);
        number("time=", (uint64_t)now.tv_sec, 10);
        images();
        fsync(crash_fd);
        for (size_t i = 0; i < sizeof(signals) / sizeof(signals[0]); i++) {
            if (signals[i] == sig) { sigaction(sig, &previous[i], NULL); break; }
        }
    } else {
        struct sigaction action = {0};
        action.sa_handler = SIG_DFL;
        sigemptyset(&action.sa_mask);
        sigaction(sig, &action, NULL);
    }
    /* 恢复并重新触发原崩溃，不吞掉系统/已有处理器；递归链第二次直接交给系统。 */
    raise(sig);
}

static int install(const char *path, const char *build) {
    if (crash_fd < 0) {
        crash_fd = open(path, O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC | O_NOFOLLOW, 0600);
        if (crash_fd < 0) return 0;
        literal("native-v1\nbuild="); literal(build);
#if defined(__aarch64__)
        literal("\nabi=arm64-v8a\n");
#else
        literal("\nabi=armeabi-v7a\n");
#endif
    }
    stack_t stack = {0};
    if (sigaltstack(NULL, &stack)) return 0;
    if (stack.ss_flags & SS_DISABLE) {
        stack.ss_sp = alternate_stack; stack.ss_size = sizeof(alternate_stack); stack.ss_flags = 0;
        if (sigaltstack(&stack, NULL)) return 0;
    }
    struct sigaction action = {0};
    action.sa_sigaction = crash;
    action.sa_flags = SA_SIGINFO | SA_ONSTACK;
    sigfillset(&action.sa_mask);
    for (size_t i = 0; i < sizeof(signals) / sizeof(signals[0]); i++) {
        struct sigaction current;
        if (sigaction(signals[i], NULL, &current)) return 0;
        if (current.sa_handler == SIG_IGN) continue;
        if (current.sa_sigaction != crash) {
            previous[i] = current;
            if (sigaction(signals[i], &action, NULL)) return 0;
        }
    }
    return 1;
}

#ifndef REPORT_TEST
JNIEXPORT jboolean JNICALL Java_com_zyj_local_ClientReports_nativeInstall(JNIEnv *env, jclass type, jstring path, jstring build) {
    (void)type;
    const char *p = (*env)->GetStringUTFChars(env, path, NULL);
    if (!p) return JNI_FALSE;
    const char *b = (*env)->GetStringUTFChars(env, build, NULL);
    int result = b ? install(p, b) : 0;
    if (b) (*env)->ReleaseStringUTFChars(env, build, b);
    (*env)->ReleaseStringUTFChars(env, path, p);
    return result ? JNI_TRUE : JNI_FALSE;
}
#else
int main(int argc, char **argv) {
    if (argc != 2 || !install(argv[1], "bbbbbbbbbbbbbbbb")) return 2;
    if (!install(argv[1], "bbbbbbbbbbbbbbbb")) return 3;
    raise(SIGABRT);
    return 99;
}
#endif
