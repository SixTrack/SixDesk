// This file is part of BOINC.
// http://boinc.berkeley.edu
// Copyright (C) 2008 University of California
//
// BOINC is free software; you can redistribute it and/or modify it
// under the terms of the GNU Lesser General Public License
// as published by the Free Software Foundation,
// either version 3 of the License, or (at your option) any later version.
//
// BOINC is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
// See the GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with BOINC.  If not, see <http://www.gnu.org/licenses/>.

// A sample assimilator that:
// 1) if success, copy the output file(s) to a directory
// 2) if failure, append a message to an error log

#include <stdio.h>
#include <unistd.h>
#include <vector>
#include <string>
#include <cstdlib>
#include <sys/types.h>
#include <sys/stat.h>
#include <dirent.h>
#include <time.h>
#include <stdlib.h>

#include "boinc_db.h"
#include "error_numbers.h"
#include "filesys.h"
#include "sched_msgs.h"
#include "sched_util.h"
#include "assimilate_handler.h"
#include "validate_util.h"
#include "sched_config.h"

using std::vector;
using std::string;

#define STR_SIZE 4096
static char *SPOOLDIR = "/afs/cern.ch/work/b/boinc";
static char *SPOOLERR = "/share/sixtrack/assimilation";
//static char *SPOOLDIR = "/afs/cern.ch/work/b/boinc/boincai08test/work";
#define NSEARCH 5	/* directories where to search for expected results */
static char *SPOOLDEP[] = {"boinc", "boinczip", "boinctest", "boincai08", "boincai08test" };

//static char *SPOOLDIR = "/afs/cern.ch/work/b/boinc/boinctest";
//static char *SPOOLDIR = "/afs/cern.ch/user/b/boinc/scratch0/boinctest";
//static char *SPOOLDIR = "/afs/cern.ch/user/b/boinc/scratch0/boinc";
static char *RESULTDIR = "results";
static char *RESULTDIR_6 = "results";
//static char *RESULTDIR_6 = "results_6";
static char *ERRORREPT = "sample_results/errors";

int write_error(int n, char* p) {
    static FILE* f = 0;
    int errnolast = errno;

    if (!f) {
        f = fopen(config.project_path(ERRORREPT), "a");
        if (!f) return ERR_FOPEN;
    }
    fprintf(f, "POS=%-2d: %d %s %s\n", n,errnolast,strerror(errnolast),p);
    fflush(f);
    return n;
}

int assimilate_handler_init(int argc, char** argv) {
  /*    for (int i=1; i<argc; i++) {
        if (!strcmp(argv[i], "--outdir")) {
            outdir = argv[++i];
        } else {
            fprintf(stderr, "bad arg %s\n", argv[i]);
	    } 
    } 
*/
    return 0;
}

void assimilate_handler_usage() {
    // describe the project specific arguments here
    fprintf(stderr,
        "    Custom options:\n"
        "    [--outdir X]  output dir for result files\n"
    );
}

int assimilate_handler( WORKUNIT& wu, vector<RESULT>& /*results*/, RESULT& canonical_result) 
{
    int retval;
    char buf[STR_SIZE];
    unsigned int i;
    int err, nstr;
    struct stat sb;

//    retval = boinc_mkdir(config.project_path(RESULTDIR));
//    if (retval) return retval;

    SCOPE_MSG_LOG scope_messages(log_messages, MSG_NORMAL);
    scope_messages.printf("[%s] Handler: Assimilating\n", wu.name);
    if (wu.canonical_resultid) {
        OUTPUT_FILE_INFO output_file;

        scope_messages.printf("[%s] Found canonical result\n", wu.name);
        log_messages.printf_multiline( MSG_DEBUG, canonical_result.xml_doc_out,"[%s] canonical result", wu.name);
        if (!(get_output_file_info(canonical_result, output_file))) {
           scope_messages.printf( "[%s] Output file path %s\n",wu.name, output_file.path.c_str());
	   // AMereghetti, 2016-10-27
	   // temporary patch against _1_sixvf_boinc1738 type of results
	   char tmpsubstr[STR_SIZE];
	   strncpy( tmpsubstr, wu.name, 14 );
	   if (strcmp(tmpsubstr,"_1_sixvf_boinc") == 0){
	     // ill wu.name
	     scope_messages.printf( "ill wu.name: %s\n",wu.name);
	     return 0;
	   }
        }
    } 
    else {
        scope_messages.printf("[%s] Handler: No canonical result\n", wu.name);
	snprintf(buf,STR_SIZE,"%s: 0x%x",wu.name,wu.error_mask);
        write_error(7,buf);
    
        if (wu.error_mask&WU_ERROR_COULDNT_SEND_RESULT) {
            log_messages.printf(MSG_CRITICAL, "[%s] HError: couldn't send a result\n", wu.name);
        }
        if (wu.error_mask&WU_ERROR_TOO_MANY_ERROR_RESULTS) {
            log_messages.printf(MSG_CRITICAL, "[%s] HError: too many error results\n", wu.name);
        }
        if (wu.error_mask&WU_ERROR_TOO_MANY_TOTAL_RESULTS) {
            log_messages.printf(MSG_CRITICAL, "[%s] HError: too many total results\n", wu.name);
        }
        if (wu.error_mask&WU_ERROR_TOO_MANY_SUCCESS_RESULTS) {
            log_messages.printf(MSG_CRITICAL, "[%s] HError: too many success results\n", wu.name);
        }
    	return  0;
    }
/*____________________________________________________________________________*/


        vector<OUTPUT_FILE_INFO> output_files;

        char dire_path[STR_SIZE];
        char copy_path[STR_SIZE];
        get_output_file_infos(canonical_result, output_files);
        unsigned int nfiles = output_files.size();
        bool file_copied = false;
	DIR *dirp = NULL;

/* find name of the directory based on the convention SPOOLDIR/dir-name__ */
	strncpy(buf,wu.name,STR_SIZE);
	buf[STR_SIZE-1] = '\0';
        char *dirnul = strstr(buf,"__");           // convention: buf contains the first part of the name = directory name
        char *dirres = (char *) (dirnul + 2);      // convention: dirres contains the second (unique) part of the name
        *dirnul = '\0';

/* iza debug:  
	int lenwname = strlen(buf);
	snprintf(dire_path,STR_SIZE,"check: files=%d len=%d - %s",n,lenwname,buf);
	write_error(0,dire_path);
   end debug */

/* iza 22/01/2014: search for directory where to copy the results:
*/
	for( err=1, i=0; i < NSEARCH; i++) {
		if( (nstr=snprintf(dire_path,STR_SIZE,"%s/%s/%s/%s",SPOOLDIR,SPOOLDEP[i],buf,RESULTDIR)) >= STR_SIZE) return write_error(1,dire_path);
        	if( (dirp = opendir(dire_path)) != NULL) { 

			closedir(dirp);		// directory exists;
			errno = 0;
			err = 0; 
			break;			// found
		} 
	}
	if ( err == 1 ){                 // directory not found or file cannot be written - write to SPOOLERR directory
          	write_error(2,buf);      // report error: spooldir does not exist!
	}
/* iza 27/02/2015: error condition added:
 */
	if( err = 0 ) {   // check that the file can be written to
		snprintf(copy_path,STR_SIZE,"%s/%s",dire_path,wu.name);
		FILE* f = fopen(copy_path, "w");
		if (errno == EFBIG) {
		          err = 1;        // warning:  may be check for all error cond?
			  write_error(3,copy_path);
		}
		else fclose(f);
	} 
	if ( err == 1 ){                 // directory not found or file cannot be written - write to SPOOLERR directory
		if( (nstr=snprintf(dire_path,STR_SIZE,"%s/%s/%s",SPOOLERR,buf,RESULTDIR)) >= STR_SIZE) return write_error(1,dire_path);
        	if( (dirp = opendir(dire_path)) != NULL) { 

			closedir(dirp);		// directory exists;
		} 
		else {
			if( (err = mkdir(dire_path, 0777)) < 0) {   // if we cannot create it, just ignore shipping back results
				write_error(9,dire_path);
				return write_error(9,": cannot create emmergency directory"); 
			}
		}
		errno = 0;
		err = 0; 
	}

/*iza debug */  
//	write_error(0,dire_path); write_error(0,dirres); 
/**/
/*
        OUTPUT_FILE_INFO& fi0 = output_files[0];
	if( (err=snprintf(copy_path,STR_SIZE,"%s/%s",dire_path,wu.name)) >= STR_SIZE) return write_error(3,copy_path);
        retval = boinc_copy(fi0.path.c_str() , copy_path);
        if( (retval = boinc_copy(fi0.path.c_str() , copy_path)) ) {
			write_error(9,(char *) fi0.path.c_str()); 
			write_error(retval,copy_path); 
	}	
        if (!retval) file_copied = true;
*/

        for (i=0; i<nfiles; i++) {

		OUTPUT_FILE_INFO& fi = output_files[i];

		if (stat(fi.path.c_str(), &sb) == -1) { write_error(20,(char *)fi.path.c_str()); continue;}

		if(i == 0) nstr=snprintf(copy_path,STR_SIZE,"%s/%s",dire_path,wu.name);
	     	else       nstr=snprintf(copy_path,STR_SIZE,"%s/%s_%d",dire_path,wu.name,i);
		if( nstr >= STR_SIZE) return write_error(1,copy_path);
/*
		FILE* f = fopen(copy_path, "w");
		if (errno == EFBIG) {
			write_error(4,copy_path);
	     		snprintf(copy_path,STR_SIZE,"%s/%s_%d",dire_path,dirres,i);
			write_error(4,copy_path);
		}
		else fclose(f);
*/
		if( (retval = boinc_copy(fi.path.c_str() , copy_path)) ) {
/* iza 27/02/2015 changed error condition:  write to local (NFS) directory in "all"
 */
                        write_error(5,copy_path);

			int errnolast = errno;
			int retval2 = 0;

			snprintf(copy_path,STR_SIZE,"%s/all/%s_%d",SPOOLERR,wu.name,i);
		        if( (retval2 = boinc_copy(fi.path.c_str() , copy_path)) ) {
				write_error(8,(char *) copy_path); 
			}

		}	
		else file_copied = true;
        }
/*

	FINISH:
	int errnolast = errno;

        if (!file_copied) {
		if( (err=snprintf(copy_path,STR_SIZE,"%s/%s_%s",dire_path,wu.name,"no_output")) >= STR_SIZE) return write_error(5,copy_path);
//on the boinc machine:            copy_path = config.project_path("%s/%s_%s",RESULTDIR, wu.name, "no_output_files");


		FILE* f = fopen(copy_path, "w");
		if (!f) write_error(6,copy_path);
		else {
    			fprintf(f, "POS=%-2d: %d %s %s\n", retval,errnolast,strerror(errnolast),copy_path);
            		fclose(f);
		}
        }
    } 
    else {
	snprintf(buf,STR_SIZE,"%s: 0x%x",wu.name,wu.error_mask);
        write_error(7,buf);
    }
*/
    return 0;
}
