#Strain and Plasmid Database
• This application is based on MySQL and Perl Dancer2. You might need to install several modules for this to work, such as Dancer2 and Template Toolkit.

• Once you’ve set up everything, run ‘query.pl’ to initiate the application.

• All the databases in this example are stored in ‘CFSlab’ schema. User name and password are ‘username’ and ‘password’, respectively. These can be configured via config.yml.

• The website uses 3000 as its port. So if you are testing it from the server computer, type “localhost:3000”.

• You may use ‘Create_Plasmid_db.pl’ to create the Plasmid database, and ‘Create_Strain_db.pl’ for the Strain database. You can use this script to create a ‘users’ database:
	CREATE TABLE 'users' ( 'ID' int(11) NOT NULL AUTO_INCREMENT, 'name' varchar(255) 	DEFAULT NULL,  'password' mediumtext NOT NULL, 'roles' CHAR(10) DEFAULT 'guest', 	'p_list' TEXT, 's_list' TEXT, PRIMARY KEY ('ID') ) ENGINE=MyISAM
Note that p_list contains information for user_customised plasmid list displaying fields, and s_list contains the one for strain list displaying fields.


• login status will stay for 1 hour (session expire didn’t work for me, so I have to ‘manually’ destroy sessions. Any advice and help is welcome!)

• “myPlasmids” and “myStrains” are the entries with Keeper field matching to your login username.

• When you try to add an entry, it will automatically assign a CFS (I’m in this lab, so…) number to the new entry.

• Antibiotic and species abbreviations can be configured through Antibiotic.yml and Species.yml. Note: try to avoid abbreviation name collapse. 

• Entries cannot be deleted, but can be marked as obsolete (by clicking “sabotage”). Once it is obsolete, the entry won’t appear in the search result. However, you cannot recycle the CFS ID for another plasmid/strain entry, and you cannot add an entry with the same plasmid/strain’s name. Due to the same reason, you cannot change the plasmid/strain’s name once it is in the database. Put it in another word, CFS ID is permanently bound to its plasmid/strain’s name once it is set! If something’s wrong with it? Ask the database’s admin. 
Note: it is always good to give your reasons in the “comments” field when you decide to “sabotage” the entry.

• It is currently possible to “revive” an entry. But I am considering to deprecate this function.

• It can remember the case of your input. But the search is case insensitive, which is convenient. Also, if you have a record named pET22b, and you try to add another one called pet22B, it won’t allow you to do so.

• Plasmid’s carriers are not editable. The field is usually modified by the changes in the strain database. Deleting or adding a plasmid in the Strain database will change the corresponding field in the Plasmid database.

• If you try to add a plasmid into a strain entry, and that plasmid is not already in the Plasmid database, you will fail. Try to add the plasmid in the database first before you do this please.

• When you add an entry, and it has a parent (parent must be already in the database for you to do so), you can type it in. Once you’ve done this, some of the fields will be pre-filled to ease your pain of form-panicking.

• Strain’s species info has to match with the species info of its parent. Otherwise any modification will fail miserably. 

• It provides mass edit, like when a paper is published and then change the ref field of a group of plasmids/strains.

• It allows owner transfer. Change owners will push previous one into the “previous owner” field, delimited with a pipe ‘|’. It also adds the time when this change happens. 

• Daughter field is not changeable, can only get updated from daughter’s parent field (same as carrier-plasmid logic). 

• It provides family tree for plasmids and strains, with construction info shown when hovering mouse over node.

• It provides garbage ground where all obsolete records are pooled. This can be secretly accessed via ‘/plasmid/obsolete’ for plasmid dumps and ‘/strain/obsolete’ for strain dumps.

• You can mass search with ID or names.

• Change species of a root parent will change the species field of all its offspring. In fact, this is the only way to change any daughter’s species field.

• It can export list to excel sheet.

• Customise fields to display on the list. p_list and s_list are stored in the user database, delimited by ‘,’.

• You can add plasmid/strain records in batch.

• Any help and advice are welcome! 
