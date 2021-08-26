package net.prominic.domino.vagrant;

import lotus.domino.Database;
import lotus.domino.DbDirectory;
import lotus.domino.NotesException;
import lotus.domino.NotesFactory;
import lotus.domino.NotesThread;
import lotus.domino.Session;

/**
 * Check whether this machine can access the given database on the given server.
 * If the process fails, report any errors from the Domino API
 *
 */
public class CheckDatabase {

    public static void main(String[] args) {
        if (args.length < 2) {
            System.out.println("Insufficient Arguments.  Usage:  ");
            System.out.println("java -jar CheckDatabase.jar <server> <database>");
            System.exit(1);
        }
        String serverName = args[0];
        String databaseName = args[1];


        try {

            NotesThread.sinitThread();
            
            Session session = NotesFactory.createSession();
            System.out.println("Running on Notes Version:  '" + session.getNotesVersion() + "'.");
            
            checkServer(session, serverName);
            
            Database database = session.getDatabase(serverName, databaseName, false);
            try {
                if (null == database || !database.isOpen()) {
                    throw new Exception("Could not open database.");
                }
                String actualServerName = session.getServerName(); //session.getServerName();
                String databaseTitle = database.getTitle();
                System.out.println("SUCCESSFUL!");
                System.out.println("Server:  '" + actualServerName + "', Database: '" + databaseTitle + "'.");
            }
            finally {
                if (null != database) {
                    database.recycle();
                    database = null;
                }
                session.recycle();
            }
        }
        catch (Throwable throwable) {
            System.out.println("FAILED!");
            throwable.printStackTrace();
        }
        finally {
            NotesThread.stermThread();
        }
    }
    
    
    public static void checkServer(Session session, String serverName) throws NotesException, Exception {
        DbDirectory directory = null;
        Database database = null;
        try {

            directory = session.getDbDirectory(serverName);
            if (null == directory) {
                throw new Exception("Unable to open directory for server '" + serverName + "'.");
            }
            else {
//                System.out.println("Successfully opened directory for server '" + serverName + "'.");
                
                database = directory.getFirstDatabase(DbDirectory.DATABASE);
                if (null == database) {
                    throw new Exception("Unable to open database for server '" + serverName + "'.");
                }
                else {
                    System.out.println("The first database on server '" + serverName + "' was '" + database.getTitle() + "'.");
                }

            }

        }
        catch (NotesException ex) {
            throw new Exception("Unable to open server '" + serverName + "':  '" + ex.text + "'.");
        }
        finally {
            if (null != database) { database.recycle(); }
            if (null != directory) { directory.recycle(); }
        }
    }

}
