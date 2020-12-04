import 'dart:async';
import 'dart:convert';
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
  Socket clientSocket;
  String textoBoton = "Conectar...";

  final picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton:
          FloatingActionButton(onPressed: sendMessage, child: Icon(Icons.send)),
      body: SingleChildScrollView(
        child: SafeArea(

                  child: Column(
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
              Center(
                child: RaisedButton(
                  onPressed: connectToServer,
                  child: Text(textoBoton),
                ),
              ),
              Center(
                child: RaisedButton(
                  onPressed: getImage,
                  child: Text("Consultar tamaño"),
                ),
              ),
              (archivo != null)
                  ? StreamBuilder(
                      builder: (_, AsyncSnapshot<List<int>> bytesArray) {
                        print(bytesArray.data.length);
                        return Container();
                      },
                      stream: leerArchivo(),
                    )
                  : Container()
            ],
          ),
        ),
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

  Stream<List<int>> leerArchivo() {
    return _image.openRead();
  }

  //===============================
  // MTEDOTO PARA LOS SOCKETS
  //===============================

  void connectToServer() async {
    // print("Destination Address: ${ipCon.text}");

    Socket.connect("192.168.100.3", 9000, timeout: Duration(seconds: 10))
        .then((socket) {
      setState(() {
        clientSocket = socket;
        textoBoton = "Conectado";
      });

      print(
          "Connected to ${socket.remoteAddress.address}:${socket.remotePort}");

      socket.listen(
        (onData) {
          final msj = Utf8Decoder().convert(onData);
          print(msj);
        },
        onDone: onDone,
        onError: onError,
      );
    }).catchError((e) {
      print(e);
    });
  }

  void onDone() {
    disconnectFromServer();
  }

  void onError(e) {
    print("onError: $e");
    disconnectFromServer();
    setState(() {
      textoBoton = "Desconectado";
    });
  }

  void disconnectFromServer() {
    print("disconnectFromServer");

    clientSocket.close();
    setState(() {
      clientSocket = null;
      textoBoton = "Desconectado";
    });
  }

  void sendMessage() async {
    //clientSocket.write("sdfgdf\n");
    //await clientSocket.addStream(archivo.openRead());
    clientSocket.write("cortar");
    int byteCount = 0;
    final stream = archivo.openRead();
    Stream<List<int>> stream2 = stream.transform(
      new StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          byteCount += data.length;
          print(byteCount);
          sink.add(data);
        },
        handleError: (error, stack, sink) {},
        handleDone: (sink) {
          sink.close();
        },
      ),
    );

    await clientSocket.addStream(stream2);
  }
}
