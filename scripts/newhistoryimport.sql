# Script to import new history data.  Out of destruction, creation.
#
# Note: This script will drop all of the hist_ tables that are generated by the import, so it
#       CAN ONLY BE USED FOR FULL IMPORTS.  This includes both the hist_new_raceentries temp
#       table and the final generated hist_raceentries / hist_entrypeoplemap tables.
#
#       It does not include the video table or orglogos table, which are managed independently.
#
# Steps for import:
# - Import the history data provided by History Committee
# - Rename tables to hist_ format. (phase 1)
#   - Additionally, this script adds indexes that appear to be useful but were not in the original
#     table definitions.
# - Normalize the mapping of people to entries. (phase 2)
# - If all is well, (manually) drop hist_new_raceentries.

##
# Phase 1:  Import new history DB from raw feed generated by histroy committee.

# Locking the tables before moving them seems like a good idea, but requires a pretty modern MySQL.
#LOCK TABLES 0buggies WRITE,
#            0orgs WRITE,
#            0people WRITE,
#            1designawards WRITE,
#            1heats WRITE,
#            1orgawards WRITE,
#            1personawards WRITE,
#            1raceentries WRITE,
#            1sweepstakes WRITE;

DROP TABLE IF EXISTS hist_buggies,
                     hist_orgs,
                     hist_people,
                     hist_designawards,
                     hist_heats,
                     hist_orgawards,
                     hist_personawards,
                     hist_new_raceentries,  # Temporary
                     hist_raceentries,      # Generated
                     hist_entrypeoplemap,   # Generated
                     hist_sweepstakes;

RENAME TABLE 0buggies TO hist_buggies,
             0orgs TO hist_orgs,
             0people TO hist_people,
             1designawards TO hist_designawards,
             1heats TO hist_heats,
             1orgawards TO hist_orgawards,
             1personawards TO hist_personawards,
             1raceentries TO hist_new_raceentries,   # Will need further processing!
             1sweepstakes TO hist_sweepstakes;

# Add some indexes that appear to be desirable.
ALTER TABLE hist_designawards ADD INDEX (buggyid);
ALTER TABLE hist_designawards ADD INDEX (orgid);
ALTER TABLE hist_heats ADD INDEX isFinalsIsReroll (isFinals, isReroll);
ALTER TABLE hist_heats ADD INDEX (year);
ALTER TABLE hist_orgawards ADD INDEX (orgid);
ALTER TABLE hist_orgawards ADD INDEX (year, award(20));
ALTER TABLE hist_sweepstakes ADD INDEX (year, role);
ALTER TABLE hist_sweepstakes ADD INDEX (personid);
ALTER TABLE hist_personawards ADD INDEX (year, award);

# If you locked the tables, unlock them.
#UNLOCK TABLES;

# To Undo, use this:
#
#LOCK TABLES hist_buggies WRITE, hist_orgs WRITE, hist_people WRITE,
#            hist_designawards WRITE, hist_heats WRITE, hist_orgawards WRITE, hist_personawards WRITE,
#            hist_raceentries WRITE, hist_sweepstakes WRITE;
#
#ALTER TABLE hist_designawards DROP INDEX orgid;
#ALTER TABLE hist_designawards DROP INDEX buggyid;
#ALTER TABLE hist_orgawards DROP INDEX orgid;
#ALTER TABLE hist_sweepstakes DROP INDEX year;
#ALTER TABLE hist_sweepstakes DROP INDEX personid;
#
#RENAME TABLE hist_buggies TO 0buggies,
#             hist_orgs TO 0orgs,
#             hist_people TO 0people,
#             hist_designawards TO 1designawards,
#             hist_heats TO 1heats,
#             hist_orgawards TO 1orgawards,
#             hist_personawards TO 1personawards,
#             hist_raceentries TO 1raceentries,
#             hist_sweepstakes TO 1sweepstakes;
#UNLOCK TABLES;


##
# Phase 2:  Normalize the race entries.
#
# This takes a denormalized race entries table (hist_new_raceentries)
# (that is, one with all of the team member person ids encoded into the table itself)
# and splits it into a normalized race entries table for production use, as well as a
# MxN mapping table
#
# Any existing contents of those tables are undisturbed, we just insert new rows.  Look out for duplicate data!
#
# THIS SCRIPT DOES NOT DROP THE TEMP TABLE, YOU MUST DO THAT YOURSELF:
# DROP TABLE hist_new_raceentries;
# (or ignore it, as it will be deleted and recreated for the next import)
#

# This is the same as the input table, but with all of the peoplecolums (e.g. PreDriver) removed.
CREATE TABLE IF NOT EXISTS `hist_raceentries` (
  `entryid` varchar(12) NOT NULL,
  `Year` int(11) DEFAULT NULL,
  `orgid` varchar(5) DEFAULT NULL,
  `Class` char(1) DEFAULT NULL,
  `Team` char(1) DEFAULT NULL,
  `Place` int(11) DEFAULT NULL,
  `buggyid` varchar(25) DEFAULT NULL,
  `Prelim` double DEFAULT NULL,
  `Reroll` double DEFAULT NULL,
  `Final` double DEFAULT NULL,
  `FinalReroll` double DEFAULT NULL,
  `DQ` varchar(128) DEFAULT NULL,
  `Note` varchar(256) DEFAULT NULL,
  PRIMARY KEY (`entryid`),
  INDEX(`buggyid`),  # Buggy
  INDEX(`class`),  # TopTimes
  INDEX `OrgClassTeam` (`orgid`,`class`,`team`),  # Org
  INDEX `YearOrgClassTeam` (`year`, `orgid`, `class`, `team`),  # Racedaylist
  INDEX `YearClassPlace` (`year`,`class`,`place`),  # Individual Raceday
  UNIQUE KEY `entryid_UNIQUE` (`entryid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

CREATE TABLE IF NOT EXISTS `hist_entrypeoplemap` (
    personid VARCHAR(10) NOT NULL,
    entryid VARCHAR(12) NOT NULL,
    heattype ENUM('Prelim', 'Prelim Reroll', 'Final', 'Final Reroll') NOT NULL,
    position ENUM('Driver', 'Hill 1', 'Hill 2', 'Hill 3', 'Hill 4', 'Hill 5') NOT NULL,
    INDEX (`personid`),
    UNIQUE INDEX one_person_per_slot (`entryid`,`heattype`,`position`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_520_ci;

START TRANSACTION;
INSERT INTO hist_raceentries
   SELECT entryid, Year, orgid, Class, Team, Place, buggyid, Prelim, Reroll, Final, FinalReroll, DQ, Note
     FROM hist_new_raceentries;

# Drivers
INSERT INTO hist_entrypeoplemap (personid, entryid, heattype, position)
   SELECT PreDriver, entryid, 'Prelim', 'Driver' FROM hist_new_raceentries
    WHERE PreDriver IS NOT NULL AND PreDriver != '0';
INSERT INTO hist_entrypeoplemap (personid, entryid, heattype, position)
   SELECT RRDriver, entryid, 'Prelim Reroll', 'Driver' FROM hist_new_raceentries
    WHERE RRDriver IS NOT NULL AND RRDriver != '0';
INSERT INTO hist_entrypeoplemap (personid, entryid, heattype, position)
   SELECT FinDriver, entryid, 'Final', 'Driver' FROM hist_new_raceentries
    WHERE FinDriver IS NOT NULL AND FinDriver != '0';
INSERT INTO hist_entrypeoplemap (personid, entryid, heattype, position)
   SELECT FinRRDriver, entryid, 'Final Reroll', 'Driver' FROM hist_new_raceentries
    WHERE FinRRDriver IS NOT NULL AND FinRRDriver != '0';

# Hill 1
INSERT INTO hist_entrypeoplemap (personid, entryid, heattype, position)
   SELECT PreH1, entryid, 'Prelim', 'Hill 1' FROM hist_new_raceentries
    WHERE PreH1 IS NOT NULL AND PreH1 != '0';
INSERT INTO hist_entrypeoplemap (personid, entryid, heattype, position)
   SELECT RRH1, entryid, 'Prelim Reroll', 'Hill 1' FROM hist_new_raceentries
    WHERE RRH1 IS NOT NULL AND RRH1 != '0';
INSERT INTO hist_entrypeoplemap (personid, entryid, heattype, position)
   SELECT FinH1, entryid, 'Final', 'Hill 1' FROM hist_new_raceentries
    WHERE FinH1 IS NOT NULL AND FinH1 != '0';
INSERT INTO hist_entrypeoplemap (personid, entryid, heattype, position)
   SELECT FinRRH1, entryid, 'Final Reroll', 'Hill 1' FROM hist_new_raceentries
    WHERE FinRRH1 IS NOT NULL AND FinRRH1 != '0';

# Hill 2
INSERT INTO hist_entrypeoplemap (personid, entryid, heattype, position)
   SELECT PreH2, entryid, 'Prelim', 'Hill 2' FROM hist_new_raceentries
    WHERE PreH2 IS NOT NULL AND PreH2 != '0';
INSERT INTO hist_entrypeoplemap (personid, entryid, heattype, position)
   SELECT RRH2, entryid, 'Prelim Reroll', 'Hill 2' FROM hist_new_raceentries
    WHERE RRH2 IS NOT NULL AND RRH2 != '0';
INSERT INTO hist_entrypeoplemap (personid, entryid, heattype, position)
   SELECT FinH2, entryid, 'Final', 'Hill 2' FROM hist_new_raceentries
    WHERE FinH2 IS NOT NULL AND FinH2 != '0';
INSERT INTO hist_entrypeoplemap (personid, entryid, heattype, position)
   SELECT FinRRH2, entryid, 'Final Reroll', 'Hill 2' FROM hist_new_raceentries
    WHERE FinRRH2 IS NOT NULL AND FinRRH2 != '0';

# Hill 3
INSERT INTO hist_entrypeoplemap (personid, entryid, heattype, position)
   SELECT PreH3, entryid, 'Prelim', 'Hill 3' FROM hist_new_raceentries
    WHERE PreH3 IS NOT NULL AND PreH3 != '0';
INSERT INTO hist_entrypeoplemap (personid, entryid, heattype, position)
   SELECT RRH3, entryid, 'Prelim Reroll', 'Hill 3' FROM hist_new_raceentries
    WHERE RRH3 IS NOT NULL AND RRH3 != '0';
INSERT INTO hist_entrypeoplemap (personid, entryid, heattype, position)
   SELECT FinH3, entryid, 'Final', 'Hill 3' FROM hist_new_raceentries
    WHERE FinH3 IS NOT NULL AND FinH3 != '0';
INSERT INTO hist_entrypeoplemap (personid, entryid, heattype, position)
   SELECT FinRRH3, entryid, 'Final Reroll', 'Hill 3' FROM hist_new_raceentries
    WHERE FinRRH3 IS NOT NULL AND FinRRH3 != '0';

# Hill 4
INSERT INTO hist_entrypeoplemap (personid, entryid, heattype, position)
   SELECT PreH4, entryid, 'Prelim', 'Hill 4' FROM hist_new_raceentries
    WHERE PreH4 IS NOT NULL AND PreH4 != '0';
INSERT INTO hist_entrypeoplemap (personid, entryid, heattype, position)
   SELECT RRH4, entryid, 'Prelim Reroll', 'Hill 4' FROM hist_new_raceentries
    WHERE RRH4 IS NOT NULL AND RRH4 != '0';
INSERT INTO hist_entrypeoplemap (personid, entryid, heattype, position)
   SELECT FinH4, entryid, 'Final', 'Hill 4' FROM hist_new_raceentries
    WHERE FinH4 IS NOT NULL AND FinH4 != '0';
INSERT INTO hist_entrypeoplemap (personid, entryid, heattype, position)
   SELECT FinRRH4, entryid, 'Final Reroll', 'Hill 4' FROM hist_new_raceentries
    WHERE FinRRH4 IS NOT NULL AND FinRRH4 != '0';

# Hill 5
INSERT INTO hist_entrypeoplemap (personid, entryid, heattype, position)
   SELECT PreH5, entryid, 'Prelim', 'Hill 5' FROM hist_new_raceentries
    WHERE PreH5 IS NOT NULL AND PreH5 != '0';
INSERT INTO hist_entrypeoplemap (personid, entryid, heattype, position)
   SELECT RRH5, entryid, 'Prelim Reroll', 'Hill 5' FROM hist_new_raceentries
    WHERE RRH5 IS NOT NULL AND RRH5 != '0';
INSERT INTO hist_entrypeoplemap (personid, entryid, heattype, position)
   SELECT FinH5, entryid, 'Final', 'Hill 5' FROM hist_new_raceentries
    WHERE FinH5 IS NOT NULL AND FinH5 != '0';
INSERT INTO hist_entrypeoplemap (personid, entryid, heattype, position)
   SELECT FinRRH5, entryid, 'Final Reroll', 'Hill 5' FROM hist_new_raceentries
    WHERE FinRRH5 IS NOT NULL AND FinRRH5 != '0';

COMMIT;
