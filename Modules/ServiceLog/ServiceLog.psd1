@{
	RootModule = "ServiceLog.psm1"
	ModuleVersion = "0.0.0.0"
	
	PrivateData = @{
		LocalLogPath  = "C:\PSsvctask\Logs"
		RemoteLogPath = "C:\PSsvctask\Logs"
		LogRetentionDays = 10
	}
}