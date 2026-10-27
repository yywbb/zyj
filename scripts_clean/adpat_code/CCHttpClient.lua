

local CCHttpClient = {
	downloadsize = 0,
	downloadmaxsize = 0,
}


function CCHttpClient.getInstance()
	return CCHttpClient
end

function CCHttpClient.setTimeoutForConnect(self,time)
	HttpClient:getInstance():setTimeoutForConnect(time)
end

function CCHttpClient.setTimeoutForRead(self,time)
	HttpClient:getInstance():setTimeoutForRead(time)
end

function CCHttpClient.send(self,request)
	self.downloadsize = 0
	request:excute()
end

function CCHttpClient.setDownloadSize( self,size )
	self.downloadsize = size
end

function CCHttpClient.getDownloadSize( self )
	return self.downloadsize
end

function CCHttpClient.getDownLoadSizeOfGet( self )
	return self.downloadsize
end

function CCHttpClient.setDownloadMaxSize( self,size )
	self.downloadmaxsize = size
end

function CCHttpClient.getDownloadMaxSize( self )
	return self.downloadmaxsize
end

return CCHttpClient