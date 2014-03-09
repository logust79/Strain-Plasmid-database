
use 5.16.0;
use strict;
use warnings;
use DBI;



my ($dbname, $user, $pwd) = qw/CFSlab username password/;
my $dbh = DBI->connect(
"dbi:mysql:dbname=$dbname",
"$user",
"$pwd",
{RaiseError => 1},
) or die $DBI::errstr;
$dbh->do("DROP TABLE IF EXISTS Strain");
$dbh->do("CREATE TABLE Strain(
ID INT PRIMARY KEY AUTO_INCREMENT,
Name CHAR(20) UNIQUE,
Species VARCHAR,
Resistance TEXT,
Plasmids TEXT,
Parent CHAR(20),
Daughters TEXT,
Genotype TEXT,
Sequence TEXT,
Temperature CHAR(7),
Constructor VARCHAR(255),
Keeper VARCHAR(255),
Pre_keeper TEXT,
Recorder VARCHAR(255),
Arrival_time DATE,
Recording_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
Modified_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
Reference TEXT,
Location VARCHAR(255),
Construction TEXT,
Comments TEXT,
Obsolete INT DEFAULT 0
)ENGINE=InnoDB"
);

