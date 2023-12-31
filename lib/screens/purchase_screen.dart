// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'database_helper.dart'; // Update with your database helper import
import 'excel_export_p.dart';
class PurchaseScreen extends StatefulWidget {
  @override
  _PurchaseScreenState createState() => _PurchaseScreenState();
}
class _PurchaseScreenState extends State<PurchaseScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<String> productNames = [];
  List<Map<String, dynamic>> purchaseData = [];
  bool isEditing = false;
  @override
  void initState() {
    super.initState();
    fetchPurchaseData(); // Call fetchData to populate the data
  }
  void enableEditing() {
    setState(() {
      isEditing = true;
    });
  }
  void saveChanges() {
    setState(() {
      isEditing = false;
    });
    // Save the updated sales data to the database
    _databaseHelper.saveChangesToPurchaseData(purchaseData);
  }
  final snackBar = const SnackBar(
    content: Text('Export Successful!'),
    duration: Duration(seconds: 2), // Adjust the duration as needed
  );

  void fetchPurchaseData() async {
      List<Map<String, dynamic>> fetchedPurchaseData =
          await _databaseHelper.getPurchaseData();
      List<Map<String, dynamic>> fetchedProductData =
          await _databaseHelper.getProductData();

      setState(() {
        purchaseData = fetchedPurchaseData;
        productNames = fetchedProductData
            .map((product) => product['name'] as String)
            .toList();
      });
  }

  Future<bool> _onWillPop() async {
    if (isEditing) {
      return await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Save Changes?'),
          content: const Text('Do you want to save your changes before leaving?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Return without saving
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                saveChanges(); // Save changes
                Navigator.of(context).pop(true); // Return and close screen
              },
              child: const Text('Yes'),
            ),
          ],
        ),
      ) ?? false; // Return false if dialog is dismissed
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final verticalScrollController = ScrollController();
    final horizontalScrollController = ScrollController();

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Purchase Data'),
          backgroundColor: Colors.blue,
          actions: [
            isEditing
                ? IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: saveChanges,
                    tooltip: 'Save',
                  )
                : IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: enableEditing,
                    tooltip: 'Edit',
                  ),
                  const SizedBox(width: 50),
                   IconButton(
        icon: const Icon(Icons.file_download), // Add an export icon
        onPressed: () {
                exportPurchaseDataToExcel(purchaseData, productNames);
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
          
        },
        tooltip: 'Export to Excel',
      ),
      const SizedBox(width: 50),
                      IconButton(
                  icon: const Icon(Icons.align_vertical_center), // Add an export icon
                  onPressed: () async {
                    DatabaseHelper dbHelper = DatabaseHelper();
                    bool updatesMade = await dbHelper.aggregatePurchaseOldData(context);
                    
                    if (updatesMade) {
                      await dbHelper.cloneAndReplacePurchaseTable();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (BuildContext context) => PurchaseScreen()),
                      );
                    }
                  },
                  tooltip: 'Combine old entries',
                ),
                const SizedBox(width: 50),
          ],
        ),
        body: productNames.isEmpty || purchaseData.isEmpty
            ? const Center(
                child: Text("No data available"),
              )
            : Scrollbar(
                controller: verticalScrollController,
                thumbVisibility: true,
                thickness: 8.0,
                radius: const Radius.circular(4.0),
                scrollbarOrientation: ScrollbarOrientation.right,
                child: SingleChildScrollView(
                  controller: verticalScrollController,
                  scrollDirection: Axis.vertical,
                  child: Scrollbar(
                    controller: horizontalScrollController,
                    thumbVisibility: true,
                    thickness: 8.0,
                    radius: const Radius.circular(4.0),
                    scrollbarOrientation: ScrollbarOrientation.top,
                    notificationPredicate: (notification) {
                      return notification is ScrollUpdateNotification;
                    },
                    child: SingleChildScrollView(
                      controller: horizontalScrollController,
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: [
                          const DataColumn(label: Text('Serial')),
                          const DataColumn(label: Text('Invoice')), // Date column
                          const DataColumn(label: Text('Date')), // Date column
                          for (var productName in productNames)
                            DataColumn(
                                label: Text(productName)), // Product columns
                        ],
                        rows: purchaseData.map((data) {
                          List<DataCell> cells = [
                            DataCell(
                              Text(data['serial'].toString()), // Display serial number
                            ),
                            DataCell(
                              isEditing
                                  ? TextFormField(
                                      initialValue: data['invoice']?.toString() ?? 'null',
                                      onChanged: (newValue) {
                                        setState(() {
                                          data['invoice'] = newValue; // Update the 'date' value
                                        });
                                      },
                                    )
                                  : Text(data['invoice']?.toString() ?? 'null'),
                            ),
                            DataCell(
                              isEditing
                                  ? TextFormField(
                                      initialValue: data['date']?.toString() ?? 'null',
                                      onChanged: (newValue) {
                                        setState(() {
                                          data['date'] = newValue; // Update the 'date' value
                                        });
                                      },
                                    )
                                  : Text(data['date']?.toString() ?? 'null'),
                            ),
                          ];

                          for (var productName in productNames) {
                            var formattedProductName =
                                productName.replaceAll(' ', '_');
                            cells.add(
                              DataCell(
                                isEditing
                                    ? TextFormField(
                                        initialValue: data[formattedProductName]?.toString() ?? '0',
                                        onChanged: (newValue) {
                                          setState(() {
                                            data[formattedProductName] = newValue; // Update the respective product value
                                          });
                                        },
                                      )
                                    : Text(data[formattedProductName]?.toString() ?? '0'),
                              ),
                            );
                          }

                          return DataRow(cells: cells);
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
