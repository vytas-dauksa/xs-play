#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <stdio.h>
#include <string.h>

STATIC AV * transform_data( HV* hash) {
	dTHX;       /* fetch context */
  char *key;
  I32 key_length;
  SV *value;

  char *key2;
  I32 key_length2;
  SV *value2;

  SV **svp;

//  I32 jj = 0;

  AV * results = (AV *)sv_2mortal((SV *)newAV());

 STRLEN l;


  // Iterate over addresses
  // takes around 0.02 sec for 200k
  hv_iterinit(hash);
  while (value = hv_iternextsv(hash, &key, &key_length)) {
    if (SvROK(value)) {
      SV * const referenced = SvRV(value);

      if (SvTYPE(referenced) == SVt_PVAV) {
//	printf("The value at key %s is reference to an array\n", key);
	      SSize_t i;
	      // Iterate over logins
	      // takes/adds around 0.03 sec
	      for ( i=0; i<(av_len((AV *) referenced)+1); i++) {
//		      printf("  checking elem %d\n", i);

			// adds around 0.01 sec
		      SV** elem = av_fetch((AV *) referenced, i, 0);

		      if (SvROK(*elem)) {
//			      printf("    SvROK returned yes\n");
			      SV * const ref = SvRV(*elem);
			      if (SvTYPE(ref) == SVt_PVHV) {
//				 printf("      found hash at %d!\n", i);

				// BLOCK takes around 0.25 sec
				// ---------------------------------------------


				  // with this total is: 0.15
				 // parse tenant, username, method
// Doesn't always work, but gives around 25% boost
//				 char * logged_in;
//				 char * username;
//				 char * tenant;
//				 char * method;
//
//				  hv_iterinit(ref);
//				  while (value2 = hv_iternextsv(ref, &key2, &key_length2)) {
//					 if ( strcmp( key2, "logged_in" ) == 0 ) {
//						 logged_in = SvRV(value2);
//						 if ( strcmp( logged_in, "true" ) != 0 ) {
//							 printf( "called\n" );
//							 break;
//						 }
//					 } else if ( strcmp( key2, "username" ) == 0 ) {
//						 username = SvRV(value2);
//					 } else if ( strcmp( key2, "method" ) == 0 ) {
//						 method = SvRV(value2);
//					 } else if ( strcmp( key2, "tenant" ) == 0 ) {
//						 tenant = SvRV(value2);
//					 }
//
//					 if ( logged_in != NULL && username != NULL && tenant != NULL && method != NULL ) {
//						  AV * res = (AV *)sv_2mortal((SV *)newAV());
//						 
//						  // adds 0.05 ( total 0.23 )
//						 av_push(res, newSVpv( key, strlen(key) ));
//		//				 av_store(res, 0, newSVpv( key, strlen(key) ) );
//
//						  // adds 0.03 ( total 0.30 - sometimes 0.33 )
//						 av_push(res, newSVpv( tenant, strlen(tenant) ));
//		//				 av_store(res, 2, newSVpv( tenant, strlen(tenant) ) );
//
//						  // adds 0.04 ( total 0.27 )
//						 SV * utf8_username = newSVpv( username, strlen(username) );
//						 SvUTF8_on(utf8_username);
//						 av_push(res, utf8_username);
//		//				 av_store(res, 1, utf8_username );
//
//
//						  // adds 0.03 ( total sometimes 0.33-0.36 )
//						 av_push(res, newSVpv( method, strlen(method) ));
//		//				 av_store(res, 3, newSVpv( method, strlen(method) ) );
//
//						 // adds another 0.04 secs per 200k if pushed 4 values directly otherwise reduces 0.04 by pushing above values here
//						 // reduces 0.04 secs per 200k ???? ( total 0.31  )//				 av_push(results, newRV((SV *) res));
//						 av_push(results, newRV((SV *) res));
//		//				 av_store(results, jj, newRV((SV *) res) );
//
//		//				 jj++;
//						break;
//					 }
//				  }


				 char * logged_in = "";
				 svp = hv_fetch((HV *) ref, "logged_in", 9, FALSE);
				 if (svp) logged_in = SvPV(*svp, l);
				 if ( strcmp( logged_in, "true" ) == 0 ) {

					 U8 * username;
					 svp = hv_fetch((HV *) ref, "username", 8, FALSE);
					 if (svp) username = SvPV(*svp, l);

					 char * tenant;
					 svp = hv_fetch((HV *) ref, "tenant", 6, FALSE);
					 if (svp) tenant = SvPV(*svp, l);

					 char * method;
					 svp = hv_fetch((HV *) ref, "method", 6, FALSE);
					 if (svp) method = SvPV(*svp, l);

					 // TODO validate it got values
					 // adds 0.02
					  AV * res = (AV *)sv_2mortal((SV *)newAV());
					 
					  // adds 0.05 ( total 0.23 )
					 av_push(res, newSVpv( key, strlen(key) ));
	//				 av_store(res, 0, newSVpv( key, strlen(key) ) );

					  // adds 0.03 ( total 0.30 - sometimes 0.33 )
					 av_push(res, newSVpv( tenant, strlen(tenant) ));
	//				 av_store(res, 2, newSVpv( tenant, strlen(tenant) ) );

					  // adds 0.04 ( total 0.27 )
					 SV * utf8_username = newSVpv( username, strlen(username) );
					 SvUTF8_on(utf8_username);
					 av_push(res, utf8_username);
	//				 av_store(res, 1, utf8_username );

					  // adds 0.03 ( total sometimes 0.33-0.36 )
					 av_push(res, newSVpv( method, strlen(method) ));
	//				 av_store(res, 3, newSVpv( method, strlen(method) ) );

					 // adds another 0.04 secs per 200k if pushed 4 values directly otherwise reduces 0.04 by pushing above values here
					 // reduces 0.04 secs per 200k ???? ( total 0.31  )//				 av_push(results, newRV((SV *) res));
					 av_push(results, newRV((SV *) res));
	//				 av_store(results, jj, newRV((SV *) res) );

	//				 jj++;

					// ---------------------------------------------

	//				 printf("     ip: %s, user: %s, ten: %s, met: %s\n", key, username, tenant, method);
				 }
			      }
			      // It's reference..
		      } else {
//			      printf("    SvROK returned no - it's scalar\n");
			      STRLEN l;
			      char *p = SvPV(*elem, l);
//			      printf("      elem %d was %s\n", i, p);
		      }
	      }
      }
      else if (SvTYPE(referenced) == SVt_PVHV) {
//         printf("The value at key %s is a reference to a hash\n", key);
      }
      else {
//         printf("The value at key %s is a reference\n", key);
      }
    } else {
//      printf("The value at key %s is not a reference\n", key);
    }
  }

  return results;
}

int print_hello_retval (void) {
	return printf("hello, world\n");
}

MODULE = Vytas		PACKAGE = Vytas

int print_hello_retval()

AV * transform_data(hash)
	HV * hash
