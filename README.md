on-updater
==================

# Description

Script to keep the verion of the database model updated, using a simple Linux script.

This script creates an auxiliar Database Table to register the executed scripts, and prevent to execute any executed script.


# Configuration

All you need to configure are under _DB config_ section. Search for "# DB config".

You can configure:

<pre>
DB_USER="USER"
DB_PASS="PASS"
DB_NAME="DB_NAME"
DB_HOST="localhost"
DB_TABLE="DB_VERSION"
DB_CHARSET="latin1"
DB_PORT="3306"
</pre>

### No use configuration

if you do not want to leave the Database data in this file, you can leave it blank as follows:

<pre>
DB_PASS=""
</pre>

or

<pre>
DB_USER=""
DB_PASS=""
</pre>

or

<pre>
DB_USER=""
DB_PASS=""
DB_NAME=""
DB_TABLE=""
</pre>

or

<pre>
DB_USER=""
DB_PASS=""
DB_NAME=""
DB_HOST=""
DB_TABLE=""
DB_PORT=""
</pre>

In this case, you need to use extra parameters to set all empty configurations.

# Use


## db_updater.sh


### Help (this)

In terminal:

<pre>bash db_updater.sh</pre>

or

<pre>bash db_updater.sh --help</pre>


### Rollback on error

To use rollback on error, tables must be transactional (InnoDB).

Use next query to set as InnoDB tables:

<pre>ALTER TABLE `TABLE_NAME` ENGINE = INNODB;</pre>


### File name format

The SQL files names must have the next format:

<pre>[version number (BIGINT)][\ \-\_\,\|\#\.][Query description][.sql]</pre>


#### Examples
File name examples:
+ 0001. Query description.sql
+ 0002 - Query description 2.sqL
+ 3 Query description 3.Sql
+ 04, Query description 4.sQl
+ 05\_Query description 5.SQL
+ 20100617-Query description with date as version number.sql
+ 201006170105#Query description with date and time as version number.sql
+ 00017|Other Query description.sql
+ 00017#Other Query description.sql


### Usage

Usage:

<pre>bash db_updater.sh [OPTIONS] ACTION [EXTRA]</pre>


#### OPTION

<pre>
-u, --user     Set DB user name to use.
               Using: 'USER'

-p, --pass     Set DB password to use.
               Using: 'PASS'
-d, --db       Set DB name to use.
               Using: 'DB_NAME'
-h, --host     Set DB host to use.
               Using: 'localhost'
-P, --port     Set DB host port to use.
               Using: '3306'
--help         This help.
</pre>


#### ACTION

<pre>
update         Execute update.
               NOTE: Transaction rollback on MySQL error.
create         Create a SQL file to mark all files as executed.
               Uses:
                 # bash db_updater.sh create [OUT FILE NAME]
                 # bash db_updater.sh create "out_file_name.sql"
                 # bash db_updater.sh create "0. Mark executed to version X.sql"
               TIP: You can use version '0' to execute before others already executed files.
mark-updated   Mark all files as executed without execute files.
</pre>
