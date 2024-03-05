A DataTable like Table with built-in support for sticky headers, zoom and scroll designed to easily replace the Flutter DataTable.

## Features
Like [DataTable2](https://pub.dev/packages/data_table_2), InteractiveDataTable is a drop in replacement for Flutter's DataTable with the following features:
- Sticky headers
- **Zoomable content**
- Draggable
- Scrollable
- Scrollbars
- **Double tap to zoom in and out**
- **Automatic column width based on content, based on algorithm from Flutter's DataTable**

![Preview](https://raw.githubusercontent.com/hlvs-apps/interactive_table/main/example/example.gif)


## Usage
**NOTE:** *Like in DataTable2, don't put the InteractiveDataTable inside unbounded parents. You don't need scrollables anymore (e.g. SingleChildScrollView) - InteractiveDataTable handles scrolling on its own. If you need an InteractiveDataTable inside a Column(), wrap it into Expanded() or Flexible().*

1. Install the package according to the [installation](https://pub.dev/packages/interactive_table/install) page.
2. Import the package:
   ```dart
   import 'package:interactive_table/interactive_table.dart';
   ```
3. Use the `InteractiveDataTable` widget:
   ```dart 
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
   }
   ```
   
## Migration from DataTable or DataTable2

If you are using DataTable or DataTable2,
you can easily migrate to InteractiveDataTable by replacing
the DataTable or DataTable2 with `TransformedDataTableBuilder`
and wrapping this builder with InteractiveDataTable.


## Additional information

I am working on adding more features to this library, such as:
- iOS like overscroll effect and bounce

Currently, the package is in early development stage, so it may contain bugs and missing features. If you find any, please report them in [GitHub issues](https://github.com/hlvs-apps/interactive_table/issues).

Any contributions are welcome. Just create an issue on GitHub before starting to work on a feature or bug fix, so the work is not duplicated.
