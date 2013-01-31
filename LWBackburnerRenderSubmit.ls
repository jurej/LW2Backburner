//----------------------------------------------------------------------------------
// LWBackburner Render Submit Script v1.4
// Updated: Michael Sherak
// Based on a script by "zardoz and Jure Judez"
// feedback: jure@ardevi.si
// feedback: michael_sherak@playstation.sony.com
//----------------------------------------------------------------------------------

// To Do:
//		1) Fix the ContentDir files to compare for fixed or arbitrary network locations
//		

// Fixed:  7-11-2012
// 		1) Scene name now used as the backburner filename. (1.3)	
//		2) The sort arrays for exporting the frames in non-sequential order. So you now can do arbitrary frame ranges. (1.2)
//		3) Updated the info area with information on what name will be sent to Backburner (1.1)
//		4) Updated the info area when batch is sent to the Manager (1.1)
//		   7-18-2012
//		1) Fixed the extra loop frame when export arbitrary frame ranges. (1.4)

@version 2.6
@warnings
@script generic
@name LWBackburnerRender

//-----------------------------------------
// Global variables
//-----------------------------------------
script_version = "1.4";
modal=1;

// Lightwave Vars
ContentDir = getdir(CONTENTDIR);
OutputPathRGB;
OutputTypeRGB;
OutputPathAlpha;
OutputTypeAlpha;
FirstFrame;     ctl_FirstFrame;
LastFrame;      ctl_LastFrame;
Render_Step;    ctl_Render_Step;

//	LWSN.exe path settings  
LWSNPath="";   ctl_LWSNPath;	// uncomment to use this instead of the hard coded line below
// LWSNPath="S:/ps2base/People/MSherak/RENDERFARM_JOBS/SNet/64bit/bin/lwsn.exe";   ctl_LWSNPath;	// Hard coded, adjust if you want to have it fixed for your users

// Backburner Vars
JobName = "";   ctl_JobName;
//scenefile = split(Scene().filename);
//JobName = scenefile[3];
JobDescription = "Lightwave RenderJob";   ctl_JobDescription;
JobPriority = 50;   ctl_JobPriority;	// Sets the job priority. The default value is 50. The other values are either 0 (Critical) or 100 (Suspended).
JobDependencies = "";   ctl_JobDependencies;
JobGroup = "";  ctl_JobGroup;
JobMaxServers = 0;  ctl_JobMaxServers;
FramesPerNode = 30;  ctl_FramesPerNode;
JobFileList;

//	Backburner settings
CmdJobPath = "C:/Program Files (x86)/Autodesk/Backburner/cmdjob.exe";    ctl_CmdJobPath;	// Most common install location for Backburner
JobTimeout = 10800;  ctl_JobTimeout;	// This is the amount of time a locked slave renderer will be reset. It is set for secs. So 3 hours for now.
JobManager = "";   ctl_JobManager;	// This is the machine on the network with the Backburner Server Manager running 
JobMask = "255.255.255.0";  ctl_JobMask;  
JobPort = 0;    ctl_JobPort;
JobWorkPath = "";   ctl_JobWorkPath;	// Working folder or directory. (ContentDir) 
JobSubFolder = "LW2BB_Job";	// This is a subfolder that will be placed in the ContentDir that Backburner will use to read and send the files. Also the location to check all the log files.
JobemailOn = 0; ctl_Jobemailon;
JobemailFrom="from@somewhere.com";  ctl_JobemailFrom;	// Sets the source email address for notification emails.
JobemailTo="to@somewhere.com";  ctl_JobemailTo;	// Sets the destination email address for notification emails.
JobemailServer="mail.somewhere.com";  ctl_JobemailServer;   // Sets the name of the SMTP email server Backburner uses to send notification emails.
JobemailCompletion=1;   ctl_JobemailCompletion;	// Sends a notification email when the job is completed.
JobemailFailure=1; ctl_JobemailFailure;	// Sends a notification email if the job fails.
// JobemailProgress:<number> 	// Sends a notification email when the number of tasks that you set are completed. Pings network a lot.

// Some script globals
configdir = getdir(SETTINGSDIR); ctl_configdir;	// Older Local Network render flag, uncomment to use this instead of the hard coded line below
// configdir = "S:/ps2base/People/MSherak/RENDERFARM_JOBS/SNet/64bit/"; ctl_configdir;  // Hard coded, adjust if you want to have it fixed for your users
sep = "\\";
filepath = configdir + sep + "backburner.cfg"; // This Lscript does write a basic config for Backburner in the config location
debug = 1;

// Disable netmask and port because it's currently not working
ctl_hidden; hidden = 0;
    
//-----------------------------------------
// LW Generic func
//-----------------------------------------
generic {
    LoadBBSettings();
    GetLWData();
    recallAll();
    
	info("( " , JobName, " ) is the currect scene name that will be used for the BackBurner job filename.");
	
    // Create UI
    if (reqisopen()){ 	// Check if requester is already open then close it
        reqabort();
    }
    //User Interface Layout Variables
    gad_w					= 500;																									// Gadget width
    gad_h                   = 20;																										// Gadget height
    gad_text_offset		= 130;																									// Gadget text offset
    num_gads				= 15;																									// Total number of gadgets vertically (for calculating the max window height)
    ui_spacing			= 4;																										// Spacing gap size
    ui_spacing_y			= 5;																										// Spacing Y gap size
    ui_offset_x			= 20;																									// Main X offset from 0
    ui_offset_y			= 25;																									// Main Y offset from 0
    ui_tab_offset			= ui_offset_y;																						// Offset for tab height
    ui_row_offset			= gad_h + ui_spacing;																			// Row offset
    ui_window_w			= ui_offset_x + gad_w + ui_offset_x;														// Window width
    ui_window_h			= ui_offset_y + (gad_h*num_gads) + (ui_spacing*(num_gads+1)) + 12;		// Window height
    ui_seperator_w 		= ui_window_w + 2;																				// Width of seperators
        
    reqbegin("LW Backburner Render Submit v" + script_version);
    reqsize(ui_window_w,ui_window_h);                                                          					// ctlposition(controlId, column, row, [width],[height],[offset])
    button_About = ctlbutton("About",80,"infobutton_callback");							ctlposition(button_About,ui_window_w-ui_offset_x-gad_w/2,ui_offset_y+(-8),gad_w/2,gad_h,gad_text_offset);
    ui_offset_y += ui_tab_offset;
    button_reset = ctlbutton("Reset Job Settings",80,"reset");							ctlposition(button_reset,ui_window_w-ui_offset_x-gad_w/2,ui_offset_y+(-8),gad_w/2,gad_h,gad_text_offset);
    ui_offset_y += ui_tab_offset;
    ctl_JobName = ctlstring("Job Name", JobName);											ctlposition(ctl_JobName,ui_offset_x,ui_offset_y,gad_w,gad_h,gad_text_offset);
    ui_offset_y += ui_tab_offset;
    ctl_JobDescription = ctlstring("Job Description", JobDescription);					ctlposition(ctl_JobDescription,ui_offset_x,ui_offset_y,gad_w,gad_h,gad_text_offset);
    ui_offset_y += ui_tab_offset;
    ui_offset_x2 = ui_offset_x;
    ctl_FirstFrame = ctlinteger("Frame Start", FirstFrame);								ctlposition(ctl_FirstFrame,ui_offset_x2,ui_offset_y,gad_w/3,gad_h,gad_text_offset);
    ui_offset_x2 += gad_w/5;
    ctl_LastFrame = ctlinteger("Frame End", LastFrame);								ctlposition(ctl_LastFrame,ui_offset_x2,ui_offset_y,gad_w/3,gad_h,gad_text_offset);
    ui_offset_x2 += gad_w/5;
    ctl_Render_Step = ctlinteger("Frame Step", Render_Step);							ctlposition(ctl_Render_Step,ui_offset_x2,ui_offset_y,gad_w/3,gad_h,gad_text_offset);
    ui_offset_x2 += gad_w/5 +(-50);
    button_resetF = ctlbutton("Reset Frame range",80,"resetFrame");				ctlposition(button_resetF,ui_offset_x2,ui_offset_y,gad_w/2,gad_h,gad_text_offset);
    ui_offset_y += ui_tab_offset;
    // ctl_optional = ctltext("","Optional Job Settings:");										ctlposition(ctl_optional,ui_offset_x,ui_offset_y,gad_w,gad_h,gad_text_offset);
	// Not really needed for Lightwave. Only needed if need to send extra commands. Mental Ray Example: -mr:RT 8 (which forces mental ray to use 8 threads, backburner just adds this extra info to the command line)
    ui_offset_y += 10;
    ctl_sep1 = ctlsep();                                                                    ctlposition(ctl_sep1,ui_offset_x,ui_offset_y+10,gad_w,gad_h,gad_text_offset);
            ctl_sep1 = ctlsep();                                                                ctlposition(ctl_sep1,ui_offset_x,ui_offset_y+10,gad_w,gad_h,gad_text_offset);
                ctl_sep1 = ctlsep();                                                                ctlposition(ctl_sep1,ui_offset_x,ui_offset_y+10,gad_w,gad_h,gad_text_offset);
    ui_offset_y += ui_tab_offset;   
    ctl_JobPriority = ctlslider("Job Priority", JobPriority,0,100);							ctlposition(ctl_JobPriority,ui_offset_x,ui_offset_y,gad_w+(-57),gad_h,gad_text_offset);
    ui_offset_y += ui_tab_offset; 
    u = 15;
    ui_offset_x2 = ui_offset_x;
    ctl_JobMaxServers = ctlinteger("Job Max Servers", JobMaxServers);			ctlposition(ctl_JobMaxServers,ui_offset_x,ui_offset_y,gad_w/3+u,gad_h,gad_text_offset);
    ui_offset_x2 += gad_w/3-u/2;
    ctl_FramesPerNode = ctlinteger("Frames per Node", FramesPerNode);		ctlposition(ctl_FramesPerNode,ui_offset_x2,ui_offset_y,gad_w/3+u,gad_h,gad_text_offset);
    ui_offset_x2 += gad_w/3-u/2;
    ctl_JobTimeout = ctlinteger("Job Timeout", JobTimeout);								ctlposition(ctl_JobTimeout,ui_offset_x2,ui_offset_y,gad_w/3+u,gad_h,gad_text_offset);
    ui_offset_y += ui_tab_offset;       
    ui_offset_y += ui_tab_offset;   
    ctl_JobGroup = ctlstring("Job Group", JobGroup);										ctlposition(ctl_JobGroup,ui_offset_x,ui_offset_y,gad_w,gad_h,gad_text_offset);
    ui_offset_y += ui_tab_offset;   
    ctl_JobDependencies = ctlstring("Dependencies", JobDependencies);			ctlposition(ctl_JobDependencies,ui_offset_x,ui_offset_y,gad_w,gad_h,gad_text_offset);
    ui_offset_y += ui_tab_offset;       
    
	// Comment out since plugins like Composite Buffer Export and Dpont Image/Pixel Filters do not update with these variables. 
    //  = ctlstring("Content Dir", ContentDir);														ctlposition(ctl_ContentDir,ui_offset_x,ui_offset_y,gad_w,gad_h,gad_text_offset);
    // ui_offset_y += ui_tab_offset;
    // ctl_OutputPathRGB = ctlstring("Output Path RGB", OutputPathRGB);		ctlposition(ctl_OutputPathRGB,ui_offset_x,ui_offset_y,gad_w,gad_h,gad_text_offset);
    // ui_offset_y += ui_tab_offset;
    // ctl_OutputPathAlpha = ctlstring("Output Path Alpha;", OutputPathAlpha); 	ctlposition(ctl_OutputPathAlpha,ui_offset_x,ui_offset_y,gad_w,gad_h,gad_text_offset);
    
    //-----------------------------------------
    // BackBurner Settings Tab
    //-----------------------------------------
    
    ui_offset_y = 25;
    ui_offset_y += ui_tab_offset;
    ctl_configdir = ctlfilename("LW config Path", configdir,,1);					ctlposition(ctl_configdir,ui_offset_x,ui_offset_y,gad_w+(-21),gad_h,gad_text_offset);
    ctlrefresh(ctl_configdir,"strip_filename");
    ui_offset_y += ui_tab_offset;   
    ctl_LWSNPath = ctlfilename("LWSN.exe Path", LWSNPath,,1);			ctlposition(ctl_LWSNPath,ui_offset_x,ui_offset_y,gad_w+(-21),gad_h,gad_text_offset);
    ui_offset_y += ui_tab_offset;   
    ctl_CmdJobPath = ctlfilename("CmdJob.exe Path", CmdJobPath,,1); 	ctlposition(ctl_CmdJobPath,ui_offset_x,ui_offset_y,gad_w+(-21),gad_h,gad_text_offset);
    ui_offset_y += ui_tab_offset;
    ui_offset_y += 10;
    ctl_sep2 = ctlsep();																			ctlposition(ctl_sep2,ui_offset_x,ui_offset_y+10,gad_w,gad_h,gad_text_offset);
    ui_offset_y += ui_tab_offset;
    ui_offset_x2 = ui_offset_x;
    t = 80;
    ctl_JobManager = ctlstring("Manager IP or name", JobManager);			ctlposition(ctl_JobManager,ui_offset_x2,ui_offset_y,gad_w/3+t,gad_h,gad_text_offset);
    ui_offset_x2 += gad_w/3+t;
    ctl_JobMask = ctlstring("Mask", JobMask);											ctlposition(ctl_JobMask,ui_offset_x2,ui_offset_y,gad_w/3,gad_h,50);
    ui_offset_x2 += gad_w/3;
    // ctl_JobPort = ctlinteger("Port", JobPort);                                           ctlposition(ctl_JobPort,ui_offset_x2,ui_offset_y,gad_w/3+(-t),gad_h,50); // Older, spacing was wrong
    ctl_JobPort = ctlinteger("Port", JobPort);											ctlposition(ctl_JobPort,ui_offset_x2,ui_offset_y,gad_w/3+(-t),gad_h,gad_text_offset-t);
    ui_offset_y += ui_tab_offset;
    ui_offset_y += 10;
    ctl_sep3= ctlsep();                                                                    		ctlposition(ctl_sep3,ui_offset_x,ui_offset_y+10,gad_w,gad_h,gad_text_offset);
    ui_offset_y += ui_tab_offset;
    t=180;
    ctl_Jobemailon = ctlcheckbox("Use Email notifications", JobemailOn);	ctlposition(ctl_Jobemailon,ui_offset_x,ui_offset_y,gad_w/2+t,gad_h,gad_text_offset);
    ui_offset_y += ui_tab_offset;
    ctl_JobemailFrom = ctlstring("Email from:", JobemailFrom);					ctlposition(ctl_JobemailFrom,ui_offset_x,ui_offset_y,gad_w/2+t,gad_h,gad_text_offset);
    ui_offset_y += ui_tab_offset;
    ctl_JobemailTo = ctlstring("Email to:", JobemailTo);								ctlposition(ctl_JobemailTo,ui_offset_x,ui_offset_y,gad_w/2+t,gad_h,gad_text_offset);
    ui_offset_y += ui_tab_offset;
    ctl_JobemailServer = ctlstring("Email server:", JobemailServer);			ctlposition(ctl_JobemailServer,ui_offset_x,ui_offset_y,gad_w/2+t,gad_h,gad_text_offset);
    ui_offset_y += ui_tab_offset;
    ctl_JobemailCompletion = ctlcheckbox("Send On Completition", JobemailCompletion);       ctlposition(ctl_JobemailCompletion,ui_offset_x,ui_offset_y,gad_w/2+t,gad_h,gad_text_offset);
    ui_offset_y += ui_tab_offset;
    ctl_JobemailFailure = ctlcheckbox("Send On Failure", JobemailFailure);	ctlposition(ctl_JobemailFailure,ui_offset_x,ui_offset_y,gad_w/2+t,gad_h,gad_text_offset);

    ctlactive(ctl_Jobemailon,"isselected",ctl_JobemailFrom,ctl_JobemailTo,ctl_JobemailServer,ctl_JobemailCompletion,ctl_JobemailFailure);
    ctl_hidden=ctlcheckbox("",hidden); ctlposition(ctl_hidden,0,0,0,0);
    ctlactive(ctl_hidden,"isselected",ctl_JobMask,ctl_JobPort);
    
    
    // TabSetups
    ctl_Tab = ctltab("RenderJob","Backburner Settings");
    ctlposition(ctl_Tab,10,15);
    ctlpage(1,button_reset,ctl_JobName,ctl_JobDescription,ctl_sep1,ctl_FirstFrame,ctl_LastFrame,ctl_Render_Step,button_resetF,
        ctl_JobPriority,ctl_JobGroup,ctl_JobMaxServers,ctl_FramesPerNode,ctl_JobDependencies, ctl_JobTimeout
        );
    ctlpage(2,ctl_configdir,ctl_LWSNPath,ctl_CmdJobPath, ctl_JobMask,ctl_JobManager,ctl_JobPort,ctl_sep2,ctl_sep3,
        ctl_Jobemailon,ctl_JobemailFrom,ctl_JobemailTo,ctl_JobemailServer,ctl_JobemailCompletion,ctl_JobemailFailure
    );
    
    if (modal){
        return if !reqpost();
        get_values();
        SaveBBSettings();
        storeAll();
        SetupBackburner();
        reqend();
    }else{
        reqopen();
    }

}

//-----------------------------------------
// Custom functions
//-----------------------------------------
GetLWData{
    scene = Scene();
    if (scene.filename == "(unnamed)"){
        error(">>>>>  Please save scene first! <<<<<");
        return;
    }
    scenefile = split(Scene().filename);
    JobName = scenefile[3];
    ContentDir = getdir(CONTENTDIR);
    OutputPathRGB = scene.rgbprefix;
    OutputPathAlpha = scene.alphaprefix;
    FirstFrame = scene.framestart;
    LastFrame = scene.frameend;
    Render_Step = scene.framestep;
    }

get_values{
    JobName = getvalue(ctl_JobName);
    JobDescription = getvalue(ctl_JobDescription);
    FirstFrame = getvalue(ctl_FirstFrame);
    LastFrame = getvalue(ctl_LastFrame);
    Render_Step = getvalue(ctl_Render_Step);
    JobPriority = getvalue(ctl_JobPriority);
    JobGroup = getvalue(ctl_JobGroup);
    JobMaxServers = getvalue(ctl_JobMaxServers);
    FramesPerNode = getvalue(ctl_FramesPerNode);
    JobDependencies = getvalue(ctl_JobDependencies);
    configdir = getvalue(ctl_configdir);
    LWSNPath = getvalue(ctl_LWSNPath);
    CmdJobPath = getvalue(ctl_CmdJobPath);
    JobTimeout = getvalue(ctl_JobTimeout);
    JobManager = getvalue(ctl_JobManager);
    JobMask = getvalue(ctl_JobMask);
    JobPort = getvalue(ctl_JobPort);
    JobemailOn =getvalue(ctl_Jobemailon);
    JobemailFrom =  getvalue(ctl_JobemailFrom);
    JobemailTo = getvalue(ctl_JobemailTo);
    JobemailServer = getvalue(ctl_JobemailServer);
    JobemailCompletion = getvalue(ctl_JobemailCompletion);
    JobemailFailure =  getvalue(ctl_JobemailFailure);
    
    FirstFrame(FirstFrame);
    LastFrame(LastFrame);
    FrameStep(Render_Step);
}

SaveBBSettings{
    outfile = File(filepath,"w");
    if (outfile) {
        outfile.writeln(configdir);
        outfile.writeln(LWSNPath);
        outfile.writeln(CmdJobPath);
        outfile.writeln(JobTimeout);
        outfile.writeln(JobManager);
        outfile.writeln(JobMask);
        outfile.writeln(JobPort);
        outfile.writeln(JobemailOn);
        outfile.writeln(JobemailFrom);
        outfile.writeln(JobemailTo);
        outfile.writeln(JobemailServer);
        outfile.writeln(JobemailCompletion);
        outfile.writeln(JobemailFailure);
        outfile.close();
    }else{
        error("Could not writte settings to ",outfile,".");
    }
}
storeAll{
 //   store("JobNameS",JobName);   // Uncomment if you want to keep the scene name used to saved
    store("JobDescriptionS",JobDescription);
    store("FirstFrameS",FirstFrame);
    store("LastFrameS",LastFrame);
    store("Render_StepS",Render_Step);
    store("JobPriorityS",JobPriority);
    store("JobGroupS",JobGroup);
    store("JobMaxServersS",JobMaxServers);
    store("FramesPerNodeS",FramesPerNode);
    store("JobDependenciesS",JobDependencies);

}
recallAll{
 //   JobName = recall("JobNameS",JobName);    // Uncomment if you want to use the last scene name that was rendered
    JobDescription = recall("JobDescriptionS",JobDescription);
    FirstFrame = recall("FirstFrameS",FirstFrame);
    LastFrame = recall("LastFrameS",LastFrame);
    Render_Step = recall("Render_StepS",Render_Step);
    JobPriority = recall("JobPriorityS",JobPriority);
    JobGroup = recall("JobGroupS",JobGroup);
    JobMaxServers = recall("JobMaxServersS",JobMaxServers);
    FramesPerNode = recall("FramesPerNodeS",FramesPerNode);
    JobDependencies = recall("JobDependenciesS",JobDependencies);
}
LoadBBSettings{
    file = File(filepath,"r");
    if (file){
        configdir = file.read();
        LWSNPath = file.read();
        CmdJobPath = file.read();
        JobTimeout = int(file.read());
        JobManager = file.read();
        JobMask = file.read();
        JobPort = int(file.read());
        JobemailOn = int(file.read());
        JobemailFrom = file.read();
        JobemailTo = file.read();
        JobemailServer = file.read();
        JobemailCompletion = int(file.read());
        JobemailFailure = int(file.read());
        file.close();
    }else{
        info("Please configure Backburner settings!");
    }
}
reset{
    GetLWData();
    setvalue(ctl_JobName, JobName);
    setvalue(ctl_FirstFrame, FirstFrame);
    setvalue(ctl_LastFrame, LastFrame);
    setvalue(ctl_Render_Step, Render_Step);
    setvalue(ctl_JobDescription,"Lightwave Job");
    setvalue(ctl_JobPriority,50);
    setvalue(ctl_JobDependencies,""); 
    setvalue(ctl_JobGroup,"");
    setvalue(ctl_JobMaxServers,0);
    setvalue(ctl_FramesPerNode,1);
    setvalue(ctl_JobTimeout,JobTimeout);

}
resetFrame{
    GetLWData();
    setvalue(ctl_FirstFrame, FirstFrame);
    setvalue(ctl_LastFrame, LastFrame);
    setvalue(ctl_Render_Step, Render_Step);
}
SetupBackburner{
    JobFolder = ContentDir + "\\" + JobSubFolder +"\\"+ JobName;
    JobLogFolder = JobFolder + "\\Log";
    spawn("cmd /c mkdir \"" + JobLogFolder + "\"");
    BakScene = JobSubFolder +"\\"+ JobName + "\\" + JobName + ".lws";
    SaveSceneCopy(fullpath(ContentDir + "\\" + BakScene));
    
    JobFile = fullpath(JobFolder + "\\" + JobName + "_Job.bat");
    FrameFile = fullpath(JobFolder + "\\" + JobName + "_Frames.txt");
    
    LWSNbatch = (fullpath(JobFolder + "\\LWSN_" + JobName +".bat"));
    lwsnw = File(LWSNbatch,"w");
    lwsnw.writeln("\"" + LWSNPath + "\" -3 -c\"" + configdir + "\" -d\"" + ContentDir + "\" \"" + BakScene + "\" %1 %2 %3");
    lwsnw.close();

    ar=0;
	Count= (LastFrame - FirstFrame);	// Needed for offset frame sorts to export correctly
	FrameCount = FirstFrame;	// Needed for offset frame sorts to export correctly
	
    if (LastFrame == FirstFrame) {
        FrameFileArray[ar+1]="LW_Frames " + LastFrame + "-" + LastFrame + " (step " + Render_Step + ")" + "\t" + LastFrame + "\t" +  LastFrame + "\t" +  Render_Step;
		}else{
				for(i = 0 ; i <= (FirstFrame + Count); i++)	// Fixed array looping for arbitrary frames
					{	
					task_frame_start = FrameCount;
					task_frame_end = FrameCount + Render_Step * FramesPerNode - Render_Step;
					if (task_frame_end > LastFrame) {
						task_frame_end = LastFrame;
					}
				FrameFileArray[ar+1]="LW_Frames " + task_frame_start + "-" + task_frame_end + " (step " + Render_Step + ")" + "\t" + task_frame_start + "\t" +  task_frame_end + "\t" +  Render_Step;
				ar += 1;
				i = (task_frame_end + Render_Step) - 1;
			FrameCount =  (task_frame_end + Render_Step) ; // - 1; caused a loop frame to render each start
			}   
		}
   
    JobFileArray[1] = "\"" + CmdJobPath + "\"";
    JobFileArray[1] += " -jobName:\"" + JobName + "\"";
    JobFileArray[1] += " -manager:" + JobManager;
    // JobFileArray[1] += " -netmask:" + JobMask;   //Older network code command
    // JobFileArray[1] += " -port:" + JobPort;      //Older network code command
    JobFileArray[1] += " -priority:" + JobPriority;
    if (JobMaxServers >0) {JobFileArray[1] += " -serverCount:" + JobMaxServers;}
    if (JobDescription !=""){ JobFileArray[1] += " -description:\"" + JobDescription + "\"";}
    JobFileArray[1] += " -taskList:\"" + FrameFile + "\"";
    if (JobDependencies !=""){  JobFileArray[1] += " -dependencies:" + JobDependencies;}
    JobFileArray[1] += " -timeout:" + JobTimeout;
    JobFileArray[1] += " -taskName:1";
    if (JobGroup!=""){          JobFileArray[1] += " -group:\"" + JobGroup + "\"";}
    JobFileArray[1] += " -logPath:\"" + JobLogFolder + "\"";
    //JobFileArray[1] += " -jobnameadjust";         //Older
    if(JobemailOn){
        JobFileArray[1] += " -emailFrom " + JobemailFrom;
        JobFileArray[1] += " -emailTo " + JobemailTo;
        JobFileArray[1] += " -emailServer " + JobemailServer;
        if(JobemailCompletion){ JobFileArray[1] += " -emailCompletion"; }
        if(JobemailFailure){ JobFileArray[1] += " -emailFailure"; }
    }
    
    JobFileArray[1] += " -attach:\"" + LWSNbatch + "\" %%tp2 %%tp3 %%tp4";
    if(debug){JobFileArray[1] += " > \"" + JobLogFolder + "\\" + JobName + "_debug.log\"";}
    
    writef(JobFileArray, JobFile);
    writef(FrameFileArray,FrameFile);

    spawn( "\"" + JobFile + "\"");
    info( JobName + " renderJob was succesfully sent to Backburner!");
        
}

//-------------------------------------------------------
// writing a file
//-------------------------------------------------------
writef: expr,outfile {
    FileOut = File(outfile,"w") || error("Cannot open file",outfile,"'");
    FileOut.open(outfile,"w");
    for(i = 1;i <= expr.size();i++)
    {
        FileOut.writeln(expr[i]); 
    }
    FileOut.close();
}
infobutton_callback {

    info("LW Backburner Render Submit script by Jure Judez : Updated by Michael Sherak 07/2012");
}

isselected:value{
    return (value==1);
}

strip_filename: input{
    inputarray = split(input);
    striplen = size(inputarray[2]);
    strip = strleft(inputarray[2], striplen+(-1));
    configdironly = inputarray[1]+strip;
    setvalue(ctl_configdir,configdironly);
}








