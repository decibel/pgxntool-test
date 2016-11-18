s/^[master [0-9a-f]+]/@GIT COMMIT@/
s/(@TEST_DIR@[^[:space:]]*).*:.*:.*/\1/
s!.*kB/s    0:00:00 \(xfr#1, to-chk=0/2\)!RSYNC OUTPUT!
s/^set [,0-9]{4,5} bytes.*/RSYNC OUTPUT/
s/(LOCATION:  [^,]+, [^:]+:).*/\1####/
s#@PG_LOCATION@/lib/pgxs/src/makefiles/../../src/test/regress/pg_regress.*#INVOCATION OF pg_regress#
s#((/bin/sh )?@PG_LOCATION@/lib/pgxs/src/makefiles/../../config/install-sh)|(/usr/bin/install)#@INSTALL@#
s#([^:])//+#\1/#g

