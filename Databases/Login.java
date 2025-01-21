import java.io.Console;           // Allows reading sensitive input like passwords securely
import java.sql.*;                // Provides SQL-related functionality
import java.util.Scanner;         // Facilitates user input

public class Login {
    // Static variable to hold the database connection throughout the session
    private static Connection connection;

    // Main method: Entry point of the program
    // @SuppressWarnings("resource")
    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in); // Scanner for non-sensitive user input
        Console console = System.console();       // Console for secure password input

        // Variables for database connection parameters
        String host = null, dbName = null, username = null, password = null;

        while (true) { // Loop to allow clearing and re-entering parameters
            System.out.println("Welcome! Please login to the database.");
            
            // Prompt for host
            System.out.print("Enter host (or type 'clear' to reset all parameters): ");
            host = scanner.nextLine(); // Read database host
            if (host.equalsIgnoreCase("clear")) {
                clearParameters();
                continue; // Restart the loop
            }

            // Prompt for database name
            System.out.print("Enter database name (or type 'clear' to reset all parameters): ");
            dbName = scanner.nextLine(); // Read database name
            if (dbName.equalsIgnoreCase("clear")) {
                clearParameters();
                continue; // Restart the loop
            }

            // Prompt for username
            System.out.print("Enter username (or type 'clear' to reset all parameters): ");
            username = scanner.nextLine(); // Read database username
            if (username.equalsIgnoreCase("clear")) {
                clearParameters();
                continue; // Restart the loop
            }

            // Securely prompt for password
            char[] passwordArray = console.readPassword("Enter password (or type 'clear' to reset all parameters): ");
            password = new String(passwordArray);
            if (password.equalsIgnoreCase("clear")) {
                clearParameters();
                continue; // Restart the loop
            }

            // Attempt to connect to the database
            connection = DatabaseConnector.connect(host, dbName, username, password);
            if (connection != null) {
                break; // Exit the loop on successful connection
            }

            System.out.println("Failed to connect. Type 'clear' to reset parameters or try again.");
        }

        // Main menu loop
        int choice;
        do {
            // Display main menu options
            System.out.println("\nMain Menu:");
            System.out.println("1. Display all digital displays");
            System.out.println("2. Search digital displays by scheduler system");
            System.out.println("3. Insert a new digital display");
            System.out.println("4. Delete a digital display");
            System.out.println("5. Update a digital display");
            System.out.println("6. Logout");
            System.out.print("Choose an option: ");
            choice = scanner.nextInt(); // Read user choice
            scanner.nextLine(); // Consume leftover newline

            // Handle menu selection using a switch statement
            switch (choice) {
                case 1 -> displayAllDisplaysSearch(); // Show all digital displays
                case 2 -> searchDisplays(scanner); // Search displays by scheduler system
                case 3 -> insertDisplay(scanner); // Insert a new display
                case 4 -> deleteDisplay(scanner); // Delete a display
                case 5 -> updateDisplay(scanner); // Update a display
                case 6 -> System.out.println("Logging out..."); // Exit menu
                default -> System.out.println("Invalid option. Please try again.");
            }
        } while (choice != 6); // Continue until user chooses to log out

        // Close the database connection
        try {
            connection.close();
            System.out.println("Disconnected from the database.");
        } catch (SQLException e) {
            // Handle errors during connection closure
            System.out.println("Error closing the connection: " + e.getMessage());
        }
    }

     // Method to clear all parameters and notify the user
     private static void clearParameters() {
        System.out.println("All parameters have been cleared. Please re-enter your login details.");
    }

    // Function to display all digital displays and allow selection of a model to view details
    private static void displayAllDisplaysSearch() {
        String query = "SELECT * FROM DigitalDisplay"; // Query to retrieve all digital displays

        try (Statement stmt = connection.createStatement();
            ResultSet rs = stmt.executeQuery(query)) { // Execute query
            System.out.println("\nDigital Displays:");
            while (rs.next()) { // Iterate through results
                System.out.println("Serial Number: " + rs.getString("serialNo")); // Display serialNo
                System.out.println("Scheduler System: " + rs.getString("schedulerSystem")); // Display schedulerSystem
                System.out.println("Model Number: " + rs.getString("modelNo")); // Display modelNo
                System.out.println("-----------------------");
            }

        // After displaying all digital displays, allow user to select a model number
        Scanner scanner = new Scanner(System.in);
            System.out.print("Enter Model Number to view details or press Enter to return to the main menu: ");
            String modelNo = scanner.nextLine();

            if (!modelNo.isBlank()) { // If user enters a model number
                displayModelDetails(modelNo); // Call function to display model details
            }

        } catch (SQLException e) {
            // Handle SQL exceptions
            System.out.println("Error retrieving digital displays: " + e.getMessage());
        }
    }

    // Function to display all digital displays and allow selection of a model to view details
    private static void displayAllDisplays() {
        String query = "SELECT * FROM DigitalDisplay"; // Query to retrieve all digital displays
    
        try (Statement stmt = connection.createStatement();
             ResultSet rs = stmt.executeQuery(query)) { // Execute query
            System.out.println("\nDigital Displays:");
            while (rs.next()) { // Iterate through results
                System.out.println("Serial Number: " + rs.getString("serialNo")); // Display serialNo
                System.out.println("Scheduler System: " + rs.getString("schedulerSystem")); // Display schedulerSystem
                System.out.println("Model Number: " + rs.getString("modelNo")); // Display modelNo
                System.out.println("-----------------------");
            }
    
        } catch (SQLException e) {
            // Handle SQL exceptions
            System.out.println("Error retrieving digital displays: " + e.getMessage());
        }
    }

// Function to display model details by model number
private static void displayModelDetails(String modelNo) {
    // Query to retrieve model details
    String query = "SELECT * FROM Model WHERE modelNo = ?";
    try (PreparedStatement pstmt = connection.prepareStatement(query)) {
        pstmt.setString(1, modelNo); // Bind modelNo to the query
        ResultSet rs = pstmt.executeQuery();

        // Display the model details if found
        if (rs.next()) {
            System.out.println("\nModel Details:");
            System.out.println("Model No: " + rs.getString("modelNo"));
            System.out.println("Width: " + rs.getDouble("width"));
            System.out.println("Height: " + rs.getDouble("height"));
            System.out.println("Weight: " + rs.getDouble("weight"));
            System.out.println("Depth: " + rs.getDouble("depth"));
            System.out.println("Screen Size: " + rs.getDouble("screenSize"));
            System.out.println("-----------------------");
        } else {
            System.out.println("No model found with the specified model number.");
        }
    } catch (SQLException e) {
        System.out.println("Error retrieving model details: " + e.getMessage());
    }
}

    // Function to search displays by scheduler system
    private static void searchDisplays(Scanner scanner) {
        System.out.print("Enter Scheduler System to search: "); // Prompt user input
        String schedulerSystem = scanner.nextLine();
        String query = "SELECT * FROM DigitalDisplay WHERE schedulerSystem = ?"; // Query with a placeholder
        try (PreparedStatement pstmt = connection.prepareStatement(query)) {
            pstmt.setString(1, schedulerSystem); // Bind user input to the query
            ResultSet rs = pstmt.executeQuery(); // Execute the query
            System.out.println("\nSearch Results:");
            while (rs.next()) { // Display each result
                System.out.println("Serial Number: " + rs.getString("serialNo"));
                System.out.println("Scheduler System: " + rs.getString("schedulerSystem"));
                System.out.println("Model Number: " + rs.getString("modelNo"));
                System.out.println("-----------------------");
            }
        } catch (SQLException e) {
            // Handle SQL exceptions
            System.out.println("Error searching data: " + e.getMessage());
        }
    }

    // Function to insert a new digital display
    private static void insertDisplay(Scanner scanner) {
        System.out.print("Enter Serial Number: "); // Read serial number
        String serialNo = scanner.nextLine();
        System.out.print("Enter Scheduler System: "); // Read scheduler system
        String schedulerSystem = scanner.nextLine();
        System.out.print("Enter Model Number: "); // Read model number
        String modelNo = scanner.nextLine();

        // Check if the model exists in the Model table
        String modelQuery = "SELECT * FROM Model WHERE modelNo = ?";
        try (PreparedStatement pstmt = connection.prepareStatement(modelQuery)) {
            pstmt.setString(1, modelNo);
            ResultSet rs = pstmt.executeQuery();

            if (!rs.next()) { // If model does not exist, prompt user to add it
                System.out.println("Model does not exist. Please provide model details:");

                System.out.print("Enter Model Width: ");
                double width = scanner.nextDouble();
                System.out.print("Enter Model Height: ");
                double height = scanner.nextDouble();
                System.out.print("Enter Model Weight: ");
                double weight = scanner.nextDouble();
                System.out.print("Enter Model Depth: ");
                double depth = scanner.nextDouble();
                System.out.print("Enter Model Screen Size: ");
                double screenSize = scanner.nextDouble();
                scanner.nextLine(); // Consume leftover newline

                // Insert the new model
                String insertModelQuery = "INSERT INTO Model(modelNo, width, height, weight, depth, screenSize) VALUES (?, ?, ?, ?, ?, ?)";
                try (PreparedStatement insertModelStmt = connection.prepareStatement(insertModelQuery)) {
                    insertModelStmt.setString(1, modelNo);
                    insertModelStmt.setDouble(2, width);
                    insertModelStmt.setDouble(3, height);
                    insertModelStmt.setDouble(4, weight);
                    insertModelStmt.setDouble(5, depth);
                    insertModelStmt.setDouble(6, screenSize);
                    insertModelStmt.executeUpdate();
                    System.out.println("New model added successfully.");
                }
            }

            // Insert the digital display
            String insertDisplayQuery = "INSERT INTO DigitalDisplay(serialNo, schedulerSystem, modelNo) VALUES (?, ?, ?)";
            try (PreparedStatement pstmt2 = connection.prepareStatement(insertDisplayQuery)) {
                pstmt2.setString(1, serialNo);
                pstmt2.setString(2, schedulerSystem);
                pstmt2.setString(3, modelNo);
                pstmt2.executeUpdate();
                System.out.println("Digital display added successfully.");
                displayAllDisplays();
            }

        } catch (SQLException e) {
            System.out.println("Error inserting data: " + e.getMessage());
        }
    }

    // Function to delete a digital display and its unused model
    private static void deleteDisplay(Scanner scanner) {
        System.out.print("Enter Serial Number to delete: "); // Prompt for serial number
        String serialNo = scanner.nextLine();

        // Query to get the model number associated with the serial number
        String getModelQuery = "SELECT modelNo FROM DigitalDisplay WHERE serialNo = ?";
        String modelNo = null;

        // Fetch the associated model number
        try (PreparedStatement pstmt = connection.prepareStatement(getModelQuery)) {
            pstmt.setString(1, serialNo);
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    modelNo = rs.getString("modelNo"); // Retrieve the model number
                } else {
                    System.out.println("Digital display not found.");
                    return; // Exit if the serial number does not exist
                }
            }
        } catch (SQLException e) {
            System.out.println("Error retrieving model information: " + e.getMessage());
            return;
        }

        // Delete the digital display
        String deleteDisplayQuery = "DELETE FROM DigitalDisplay WHERE serialNo = ?";
        try (PreparedStatement pstmt = connection.prepareStatement(deleteDisplayQuery)) {
            pstmt.setString(1, serialNo);
            pstmt.executeUpdate();
            System.out.println("Digital display deleted successfully.");
            displayAllDisplays();
            displayAllModels();
        } catch (SQLException e) {
            System.out.println("Error deleting digital display: " + e.getMessage());
        }

        // Check if the model is still used by any other display
        String checkModelUsageQuery = "SELECT COUNT(*) FROM DigitalDisplay WHERE modelNo = ?";
        try (PreparedStatement pstmt = connection.prepareStatement(checkModelUsageQuery)) {
            pstmt.setString(1, modelNo);
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next() && rs.getInt(1) == 0) { // If the model is no longer used
                    String deleteModelQuery = "DELETE FROM Model WHERE modelNo = ?"; // Delete unused model
                    try (PreparedStatement pstmt2 = connection.prepareStatement(deleteModelQuery)) {
                        pstmt2.setString(1, modelNo);
                        pstmt2.executeUpdate();
                        System.out.println("Model " + modelNo + " deleted successfully.");
                    }
                }
            }
        } catch (SQLException e) {
            System.out.println("Error checking model usage: " + e.getMessage());
        }
    }

    // Function to display all models
    private static void displayAllModels() {
        String query = "SELECT * FROM Model"; // Query to retrieve all models
        try (Statement stmt = connection.createStatement();
             ResultSet rs = stmt.executeQuery(query)) {
            System.out.println("\nModels:");
            while (rs.next()) { // Iterate through results
                System.out.println("Model No: " + rs.getString("modelNo"));
                System.out.println("Width: " + rs.getDouble("width"));
                System.out.println("Height: " + rs.getDouble("height"));
                System.out.println("Weight: " + rs.getDouble("weight"));
                System.out.println("Depth: " + rs.getDouble("depth"));
                System.out.println("Screen Size: " + rs.getDouble("screenSize"));
                System.out.println("-----------------------");
            }
        } catch (SQLException e) {
            System.out.println("Error retrieving model data: " + e.getMessage());
        }
    }

    // Function to update a digital display
    private static void updateDisplay(Scanner scanner) {
        System.out.print("Enter Serial Number to update: "); // Prompt for serial number
        String serialNo = scanner.nextLine();
        System.out.print("Enter new Scheduler System: "); // Prompt for updated scheduler system
        String schedulerSystem = scanner.nextLine();
        System.out.print("Enter new Model Number: "); // Prompt for updated model number
        String modelNo = scanner.nextLine();

        // Query to update the digital display
        String query = "UPDATE DigitalDisplay SET schedulerSystem = ?, modelNo = ? WHERE serialNo = ?";
        try (PreparedStatement pstmt = connection.prepareStatement(query)) {
            pstmt.setString(1, schedulerSystem); // Bind new scheduler system
            pstmt.setString(2, modelNo); // Bind new model number
            pstmt.setString(3, serialNo); // Bind serial number
            pstmt.executeUpdate();
            System.out.println("Digital display updated successfully.");
            displayAllDisplays();
        } catch (SQLException e) {
            System.out.println("Error updating data: " + e.getMessage());
        }
    }
}
