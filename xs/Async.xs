/*
 *  Copyright 2009 10gen, Inc.
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */
#include "CoroAPI.h"
#include "perl_mongo.h"
#include "mongo_link.h"

extern XS(boot_MongoDB__Async__Connection);
extern XS(boot_MongoDB__Async__BSON);
extern XS(boot_MongoDB__Async__Cursor);
extern XS(boot_MongoDB__Async__OID);


MODULE = MongoDB::Async  PACKAGE = MongoDB::Async

PROTOTYPES: DISABLE

BOOT:
	get_coro_ev_api();

	request_id = rand();
	
        if (items < 3)
            croak("machine id required");

        perl_mongo_machine_id = SvIV(ST(2));

	PERL_MONGO_CALL_BOOT (boot_MongoDB__Async__Connection);
	PERL_MONGO_CALL_BOOT (boot_MongoDB__Async__BSON);
	PERL_MONGO_CALL_BOOT (boot_MongoDB__Async__Cursor);
	PERL_MONGO_CALL_BOOT (boot_MongoDB__Async__OID);
        gv_fetchpv("MongoDB::Async::Cursor::_request_id",  GV_ADDMULTI, SVt_IV);
        gv_fetchpv("MongoDB::Async::Cursor::slave_okay",  GV_ADDMULTI, SVt_IV);
        gv_fetchpv("MongoDB::Async::BSON::looks_like_number",  GV_ADDMULTI, SVt_IV);
        gv_fetchpv("MongoDB::Async::BSON::char",  GV_ADDMULTI, SVt_IV);
        gv_fetchpv("MongoDB::Async::BSON::utf8_flag_on",  GV_ADDMULTI, SVt_IV);
        gv_fetchpv("MongoDB::Async::BSON::use_boolean",  GV_ADDMULTI, SVt_IV);

void
write_query(ns, opts, skip, limit, query, fields = 0)
         char *ns
         int opts
         int skip
         int limit
         SV *query
         SV *fields
     PREINIT:
         buffer buf;
         mongo_msg_header header;
         HV *info = newHV();
         SV **heval;
     PPCODE:
		 CREATE_BUF(INITIAL_BUF_SIZE);
         CREATE_HEADER_WITH_OPTS(buf, ns, OP_QUERY, opts);
		 
         heval = hv_store(info, "ns", 2, newSVpv(ns, strlen(ns)), 0);
         heval = hv_store(info, "opts", 4, newSViv(opts), 0);
         heval = hv_store(info, "skip", 4, newSViv(skip), 0);
         heval = hv_store(info, "limit", 5, newSViv(limit), 0);
         heval = hv_store(info, "request_id", 10, newSViv(request_id), 0);

		 
         perl_mongo_serialize_int(&buf, skip);
         perl_mongo_serialize_int(&buf, limit);

         perl_mongo_sv_to_bson(&buf, query, NO_PREP);

         if (fields && SvROK(fields)) {
           perl_mongo_sv_to_bson(&buf, fields, NO_PREP);
         }

         perl_mongo_serialize_size(buf.start, &buf);

		 EXTEND(SP, 2);
         PUSHs(sv_2mortal(newSVpvn(buf.start, buf.pos-buf.start)));
         PUSHs(sv_2mortal(newRV_noinc((SV*)info)));

         Safefree(buf.start);


void
write_insert(ns, a, add_ids)
         char *ns
         AV *a
         int add_ids
     PREINIT:
         buffer buf;
         mongo_msg_header header;
         int i;
         AV *ids = 0;
     INIT:
         if (add_ids) {
            ids = newAV();
         }
     PPCODE:
			
         CREATE_BUF(INITIAL_BUF_SIZE);
         CREATE_HEADER(buf, ns, OP_INSERT);

         for (i=0; i<=av_len(a); i++) {
           int start = buf.pos-buf.start;
           SV **obj = av_fetch(a, i, 0);
           perl_mongo_sv_to_bson(&buf, *obj, ids);
         }
         perl_mongo_serialize_size(buf.start, &buf);

		 
         XPUSHs(sv_2mortal(newSVpvn(buf.start, buf.pos-buf.start)));
         if (add_ids) {
           XPUSHs(sv_2mortal(newRV_noinc((SV*)ids)));
         }

         Safefree(buf.start);

void
write_remove(ns, criteria, flags)
         char *ns
         SV *criteria
         int flags
     PREINIT:
         buffer buf;
         mongo_msg_header header;
     PPCODE:

         CREATE_BUF(INITIAL_BUF_SIZE);
         CREATE_HEADER(buf, ns, OP_DELETE);
         perl_mongo_serialize_int(&buf, flags);
         perl_mongo_sv_to_bson(&buf, criteria, NO_PREP);
         perl_mongo_serialize_size(buf.start, &buf);

         XPUSHs(sv_2mortal(newSVpvn(buf.start, buf.pos-buf.start)));
         Safefree(buf.start);

void
write_update(ns, criteria, obj, flags)
         char *ns
         SV *criteria
         SV *obj
         int flags
    PREINIT:
         buffer buf;
         mongo_msg_header header;
    PPCODE:

         CREATE_BUF(INITIAL_BUF_SIZE);
         CREATE_HEADER(buf, ns, OP_UPDATE);
         perl_mongo_serialize_int(&buf, flags);
         perl_mongo_sv_to_bson(&buf, criteria, NO_PREP);
         perl_mongo_sv_to_bson(&buf, obj, NO_PREP);
         perl_mongo_serialize_size(buf.start, &buf);

         XPUSHs(sv_2mortal(newSVpvn(buf.start, buf.pos-buf.start)));
         Safefree(buf.start);

void
read_documents(sv)
         SV *sv
    PREINIT:
         buffer buf;
    PPCODE:
         buf.start = SvPV_nolen(sv);
         buf.pos = buf.start;
         buf.end = buf.start + SvCUR(sv);

         while(buf.pos < buf.end) {
             XPUSHs(sv_2mortal(perl_mongo_bson_to_sv(&buf)));
         }

