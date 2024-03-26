import 'package:flutter/material.dart';
import 'package:interactive_table/interactive_table.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Interactive Table Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const InteractiveDataTableExample(),
    );
  }
}

class InteractiveDataTableExample extends StatelessWidget {
  const InteractiveDataTableExample({super.key});

  final String title = 'InteractiveDataTable Example';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: InteractiveDataTable(
        transformedDataTableBuilder: TransformedDataTableBuilder(
          columns: const [
            DataColumn(label: Text('Column 1')),
            DataColumn(label: Text('Column 2')),
            DataColumn(label: Text('Column 3')),
            DataColumn(label: Text('Column 4')),
            DataColumn(label: Text('Column 5')),
          ],
          rows: [
            for (int i = 1; i <= 20; i++)
              DataRow(
                  cells: [
                    DataCell(Text('Row $i, Cell 1')),
                    DataCell(Text('Row $i, Cell 2')),
                    DataCell(Text('Row $i, Cell 3')),
                    DataCell(Text('Row $i, Cell 4')),
                    DataCell(Text('Row $i, Cell 5')),
                  ],
                  onSelectChanged: (_) {
                    print('Row $i tapped');
                  },
              ),
          ],
        ),
      ),
    );
  }

 /* @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: BetterInteractiveViewer(
        maxScale: 4,
        child: Container(
          decoration: const BoxDecoration(boxShadow: [
            BoxShadow(
              offset: Offset(-20, 20),
              color: Colors.red,
              blurRadius: 15,
              spreadRadius: -10,
            ),
            BoxShadow(
              offset: Offset(-20, -20),
              color: Colors.orange,
              blurRadius: 15,
              spreadRadius: -10,
            ),
            BoxShadow(
              offset: Offset(20, -20),
              color: Colors.blue,
              blurRadius: 15,
              spreadRadius: -10,
            ),
            BoxShadow(
              offset: Offset(20, 20),
              color: Colors.deepPurple,
              blurRadius: 15,
              spreadRadius: -10,
            )
          ]),
          child: Container(
            width: 200,
            height: 200,
            color: Colors.amber,
            child: const Center(
                child: Text(
              'Text',
              style: TextStyle(color: Colors.white, fontSize: 40),
            )),
          ),
        ),
      ),
    );
  }*/
}
