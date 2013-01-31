Explanation of the parameters:

Job Name:  				Sets the job name.
JobDescription:			Defines a description of the job.

Frame Start:				Same as LW setting.
Frame End:				Same as LW setting.
Frame Step:				Same as LW setting.
Reset Frame range:	Will reset frame range to the ones set in rende globals.

Job Priority:				Sets the job priority. The default value is 50. The other values are either 0 (Critical) or 100 (Suspended).

Dependencies:			Defines a list of job dependencies (job names separated with semicolons).
Job Group:				Defines the server group to which the job is submitted.
Job Max Servers:		Sets the maximum number of servers that can simultaneously work on the job. 
Frames Per Node:		Defines the number of frames each server will accept in a batch.

LW config Path:			Path to LW config dir (you can choose any file and the path will be stripped automatically). 
								By default this is set to your LW setup. However you can specify different path if you want to run with different config on your farm.
LWSN Path:				Path to LWSN.exe. It should be on a shared drive accesibly by all your nodes.
CmdJob Path:			Path to cmdjob.exe. This is usualy in C:\Program Files (x86)\Autodesk\Backburner\cmdjob.exe
Manager: 					Sets the name or IP of the manager.
Mask:						Subnet mask for Manager. This does not seem to work so it's currently disabled.
Port:							Port for Manager. This does not seem to work so it's currently disabled.

Email From:				Sets the source email address for notification emails.
Email To:					Sets the destination email address for notification emails.
Email Server:			Sets the name of the SMTP email server Backburner uses to send notification emails.
Email Completion:		Sends a notification email when the job is completed.
Email Failure:			Sends a notification email if the job fails.

Reset button:			Will reset Job tab settings to defaults.

If you find this script useful feel free to donate to my paypal account: jure@ardevi.si

FAQ:

Q: Some nodes are not rendering correct frames.
A: Make sure that all your nodes are using the same version of Backburner.

Q: Win7: I can get the job to submit to backburner but when it tries to execute tne bat file it reurns an error:
“access is denied. (0x5) “Task error:Process cannot be added to job group” “Process cannot be added to job group”

A: Make sure backburner server is "run as administrator" with admin privileges.
