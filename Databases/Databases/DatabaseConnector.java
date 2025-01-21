import java.sql.Connection;        // Represents a connection to the database
import java.sql.DriverManager;     // Utility for managing database connections
import java.sql.SQLException;      // Handles SQL-specific exceptions

// Class responsible for establishing a connection to a MySQL database
public class DatabaseConnector {
    // MySQL JDBC driver class
    private static final String JDBC_DRIVER = "com.mysql.cj.jdbc.Driver";

    /**
     * Establishes a connection to the database.
     *
     * @param host     The hostname or IP address of the database server (e.g., "localhost").
     * @param dbName   The name of the database to connect to.
     * @param username The database username.
     * @param password The database password.
     * @return A Connection object if the connection is successful, otherwise null.
     */
    public static Connection connect(String host, String dbName, String username, String password) {
        Connection connection = null; // Connection object to return
    
        try {
            // Load the MySQL JDBC driver
            Class.forName(JDBC_DRIVER);
    
            // Construct the database URL with the additional parameter
            String url = "jdbc:mysql://" + host + "/" + dbName + "?useSSL=false&allowPublicKeyRetrieval=true";
    
            // Establish the connection with the provided credentials
            connection = DriverManager.getConnection(url, username, password);
            System.out.println("Connected to the database successfully!");
        } catch (ClassNotFoundException e) {
            // Handle the case where the JDBC driver is missing
            System.out.println("JDBC Driver not found. Ensure MySQL Connector/J is included.");
        } catch (SQLException e) {
            // Handle SQL-related issues (e.g., authentication failure, unreachable host)
            System.out.println("Connection failed: " + e.getMessage());
        }
    
        // Return the connection (or null if an error occurred)
        return connection;
    }
}    
