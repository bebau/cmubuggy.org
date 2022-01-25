# One time script for import of new database history tables provided by Jeremy circa Jan 2022.
#
# Note: This script will drop all of the hist_ tables that are generated by the import, so it
#       CAN ONLY BE USED FOR FULL IMPORTS.  This includes both the hist_new_raceentries temp
#       table and the final generated hist_raceentries / hist_entrypeoplemap tables.
#
# Steps for import:
# - Import the history data provided by Jeremy
# - Run this script to rename tables to hist_ format.
#   - Additionally, this script adds indexes that appear to be useful but were not in the original
#     table definitions.
# - Run second script to denormalize hist_new_raceentries table into hist_raceentries and hist_entrypeoplemap
# - If all is well, (manually) drop hist_new_raceentries.

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
ALTER TABLE hist_sweepstakes ADD INDEX (year);
ALTER TABLE hist_sweepstakes ADD INDEX (personid);

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
