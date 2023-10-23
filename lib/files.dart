import 'package:flutter/material.dart';
import 'openedFilePage.dart'; // Tuo OpenedFilePage

class FileItem {
  final String name;
  final String date;
  final String folderName;

  FileItem({
    required this.name,
    required this.date,
    required this.folderName,
  });
}

final List<FileItem> filenames = <FileItem>[
  FileItem(name: 'Memo 1', date: '23.10.2023', folderName: 'Meeting notes'),
  FileItem(name: 'Memo 2', date: '15.10.2023', folderName: 'Meeting notes'),
  FileItem(name: 'Memo 3', date: '4.10.2023', folderName: 'Email drafts'),
  FileItem(name: 'Memo 4', date: '4.10.2023', folderName: 'Ideas'),
  FileItem(name: 'Memo 5', date: '1.10.2023', folderName: 'Ideas'),
  FileItem(name: 'Memo 6', date: '27.9.2023', folderName: 'Ideas'),
  FileItem(name: 'Memo 7', date: '25.9.2023', folderName: 'Meeting notes'),
];

final List<String> foldernames = <String>[
  'Meeting notes',
  'Email drafts',
  'Ideas',
];

class FilesPage extends StatefulWidget {
  const FilesPage({Key? key}) : super(key: key);

  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  bool isFoldersTabSelected = false;
  String selectedFolder = '';
  List<String> selectedFolderContent = [];

  void _showCreateFolderDialog(BuildContext context) {
    String newFolderName = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create a New Folder'),
          content: TextField(
            onChanged: (value) {
              newFolderName = value;
            },
            decoration: const InputDecoration(labelText: 'Folder Name'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (newFolderName.isNotEmpty) {
                  setState(() {
                    foldernames.add(newFolderName);
                  });
                }
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _openFile(FileItem fileItem) {
    // Avaa tiedosto valitussa näkymässä
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OpenedFilePage(title: fileItem.name),
      ),
    );
  }

  void _openFolder(String folderName) {
    setState(() {
      selectedFolder = folderName;
      isFoldersTabSelected = true;
      selectedFolderContent = getFolderContent(folderName);
    });

    // Avaa kansion sisällön uudessa näkymässä
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FolderViewPage(
          folderName: folderName,
          folderContent: selectedFolderContent,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Files'),
          bottom: TabBar(
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: [
              Tab(
                text: 'All',
              ),
              Tab(
                text: 'Folders',
              ),
            ],
            onTap: (index) {
              setState(() {
                isFoldersTabSelected = index == 1;
              });
            },
          ),
        ),
        body: TabBarView(
          children: [
            ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: filenames.length,
              itemBuilder: (BuildContext context, int index) {
                FileItem fileItem = filenames[index];
                return Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: Text(fileItem.name),
                      subtitle: Text(fileItem.date),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () {
                        _openFile(fileItem);
                      },
                    ),
                    const Divider(),
                  ],
                );
              },
            ),
            // Folders Tab
            ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: foldernames.length,
              itemBuilder: (BuildContext context, int index) {
                String folderName = foldernames[index];
                return Column(
                  children: [
                    ListTile(
                      title: Text(folderName),
                      leading: const Icon(Icons.folder_outlined),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () {
                        _openFolder(folderName);
                      },
                    ),
                    const Divider(),
                  ],
                );
              },
            ),
          ],
        ),
        floatingActionButton: isFoldersTabSelected
            ? FloatingActionButton(
                onPressed: () {
                  _showCreateFolderDialog(context);
                },
                shape: const CircleBorder(),
                child: const Icon(Icons.add),
              )
            : null,
      ),
    );
  }

  List<String> getFolderContent(String folderName) {
    // Tässä voit hakea kansion sisällön jostain lähteestä
    // Palauta luettelo tiedostoista tai muusta sisällöstä
    // Tässä vaiheessa voit palauttaa yksinkertaisesti tyhjän luettelon
    return [];
  }
}

class FolderViewPage extends StatelessWidget {
  final String folderName;
  final List<String> folderContent;

  FolderViewPage({
    required this.folderName,
    required this.folderContent,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(folderName),
        ),
        body: ListView.builder(
          itemCount: folderContent.length,
          itemBuilder: (BuildContext context, int index) {
            String content = folderContent[index];
            return ListTile(
              title: Text(content),
            );
          },
        ));
  }
}
