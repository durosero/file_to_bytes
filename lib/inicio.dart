import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class InicioPage extends StatefulWidget {
  @override
  _InicioPageState createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  File _image;
  File archivo;

  final picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          (archivo != null)
              ? Image(image: AssetImage(archivo.path))
              : Container(),
          Center(
            child: RaisedButton(
              onPressed: getImage,
              child: Text("Seleccionar"),
            ),
          ),
        ],
      ),
    );
  }

  Future getImage() async {
    List<int> bytesLista = [];
    archivo = null;

 
    final pickedFile = await picker.getImage(source: ImageSource.camera);

    if (pickedFile != null) {
      _image = File(pickedFile.path);

      try {
        Uint8List bytes;

        await _image.readAsBytes().then((value) {
          bytes = Uint8List.fromList(value);

          print("object");
        }).catchError((onError) {
          print(onError);
        });

        print("Numero de bytes: ");
        print(bytes.length);

      
        for (var i = 0; i < bytes.length; i++) {
          bytesLista.add(bytes[i]);
        }
        print("tamaño de la lista:");
        print(bytesLista.length);
        
        Uint8List newImage = Uint8List.fromList(bytesLista);

        print("tamaño de la nueva newImage :" + newImage.length.toString());

       ByteData archivoBytes = ByteData.view(newImage.buffer);


        archivo = await writeToFile(archivoBytes);
        if (archivo == null) {
          print("EL archivo esta vacio");
        } else {
          print("El archivo esta lleno");
        }
        setState(() {});
      } catch (e) {
        print(e);
      }
    } else {
      print('No image selected.');
    }
  }

  Future<File> writeToFile(ByteData data) async {
    final buffer = data.buffer;
    Directory tempDir = await getTemporaryDirectory();
    String tempPath = tempDir.path;
    var filePath = tempPath +
        '/file_01_' +
        DateTime.now().millisecondsSinceEpoch.toString() +
        ".jpg"; // file_01.tmp is dump file, can be anything
    print(filePath);
    return new File(filePath).writeAsBytes(
        buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  }
}
