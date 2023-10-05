import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maid/ModelFilePath.dart';
import 'package:maid/lib.dart';
import 'package:maid/llama_params.dart';
import 'package:system_info_plus/system_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String log = "";
  String result = "";
  Lib? lib;

  String _ram = "\nCalcul en cours...";
  Color color = Colors.black;
  ParamsLlama paramsLlama = ParamsLlama();

  var promptController = TextEditingController();

  final ScrollController _consoleScrollController = ScrollController();

  String prePrompt = "";

  List<String> defaultPrePrompts = [
    'Transcript of a dialog, where the User interacts with an Assistant named Bob. Bob is helpful, kind, honest, good at writing, and never fails to answer the User\'s requests immediately and with precision.\n\n'
      'User: Hello, Bob.\n'
      'Bob: Hello. How may I help you today?\n'
      'User: Please tell me the largest city in Europe.\n'
      'Bob: Sure. The largest city in Europe is Moscow, the capital of Russia.\n'
      'User:',
    'Maid: Hello, I\'m Maid, your personal assistant. I can write, complex mails, code and even songs\n'
        'User: Hello how are you ?\n'
        'Maid: I\'m fine, thank you. How are you ?\n'
        'User: I\'m fine too, thanks.\n'
        'Maid: That\'s good to hear\n'
        'User:',
  ];

  bool inProgress = false;

  FileState fileState = FileState.notFound;

  TextEditingController reversePromptController = TextEditingController();

  // Memory? _memory;

  bool showLog = false;
  bool showParams = false;
  bool showParamsFineTune = false;

  toggleShowLog() {
    setState(() {
      showLog = !showLog;
    });
  }

  toggleShowFineTune() {
    setState(() {
      showParamsFineTune = !showParamsFineTune;
    });
  }

  void scrollDown() {
    _consoleScrollController.animateTo(
      _consoleScrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 50),
      curve: Curves.easeOut,
    );
  }

  void printLnLog(String log) {
    setState(() {
      this.log += "$log\n";
    });
    scrollDown();
  }

  void printResult(String log) {
    setState(() {
      result += log;
    });
    scrollDown();
  }

  bool canStop = false;
  void done() {
    setState(() {
      inProgress = false;
    });
  }

  void canUseStop() {
    setState(() {
      canStop = true;
    });
  }

  void _exec() {
    //close the keyboard if on mobile
    if (Platform.isAndroid || Platform.isIOS) {
      FocusScope.of(context).unfocus();
    }
    setState(() {
      inProgress = true;
    });
    if (lib == null) {
      lib = Lib();
      lib?.executeBinary(
        //
        // class ParamsLlamaValuesOnly {
        // bool memory_f16;
        // bool random_prompt;
        // bool use_color;
        // bool interactive;
        // bool interactive_start;
        // bool instruct;
        // bool ignore_eos;
        // bool perplexity;
        // String seed;
        // String n_threads;
        // String n_predict;
        // String repeat_last_n;
        // String n_parts;
        // String n_ctx;
        // String top_k;
        // String top_p;
        // String temp;
        // String repeat_penalty;
        // String n_batch;
        //
        // ParamsLlamaValuesOnly({
        // required this.memory_f16,
        // required this.random_prompt,
        // required this.use_color,
        // required this.interactive,
        // required this.interactive_start,
        // required this.instruct,
        // required this.ignore_eos,
        // required this.perplexity,
        // required this.seed,
        // required this.n_threads,
        // required this.n_predict,
        // required this.repeat_last_n,
        // required this.n_parts,
        // required this.n_ctx,
        // required this.top_k,
        // required this.top_p,
        // required this.temp,
        // required this.repeat_penalty,
        // required this.n_batch,
        // });
        // }

        paramsLlamaValuesOnly: ParamsLlamaValuesOnly(
          memory_f16: paramsLlama.memory_f16,
          random_prompt: paramsLlama.random_prompt,
          use_color: paramsLlama.use_color,
          interactive: paramsLlama.interactive,
          interactive_start: paramsLlama.interactive_start,
          instruct: paramsLlama.instruct,
          ignore_eos: paramsLlama.ignore_eos,
          perplexity: paramsLlama.perplexity,
          seed: paramsLlama.seedController.text,
          n_threads: paramsLlama.n_threadsController.text,
          n_predict: paramsLlama.n_predictController.text,
          repeat_last_n: paramsLlama.repeat_last_nController.text,
          n_parts: paramsLlama.n_partsController.text,
          n_ctx: paramsLlama.n_ctxController.text,
          top_k: paramsLlama.top_kController.text,
          top_p: paramsLlama.top_pController.text,
          temp: paramsLlama.tempController.text,
          repeat_penalty: paramsLlama.repeat_penaltyController.text,
          n_batch: paramsLlama.n_batchController.text,
        ),
        printLnLog: printLnLog,
        printLog: printResult,
        promptPassed: prePrompt,
        firstInteraction: promptController.text.trim() +
            (promptController.text.isEmpty ? "" : "\n"),
        done: done,
        canStop: canUseStop,
        stopToken: reversePromptController.text,
      );
    } else {
      lib?.newPromp(
          " ${promptController.text.trim()}${promptController.text.isEmpty ? "" : "\n"}");
    }
    setState(() {
      promptController.text = "";
    });
  }

  void _cancel() {
    lib?.cancel(
        // printLnLog: printLnLog,
        // printLog: printLog,
        );
  }

  @override
  initState() {
    super.initState();
    initDefaultPrompts();
    getRam();

    testFileExisting();
  }

  void getRam() async {
    try {
      if (Platform.isWindows == false) {
        int? deviceMemory = await SystemInfoPlus.physicalMemory;
        int deviceMemoryGB = (deviceMemory ?? 0) ~/ 1024 + 1;

        setState(() {
          _ram = "${deviceMemoryGB}GB";
          if (deviceMemoryGB <= 6) {
            _ram += " (WARNING ! May not be enough)";
          } else {
            _ram += " (Should be enough)";
          }
          color = deviceMemoryGB > 6
              ? Colors.green
              : deviceMemoryGB > 4
                  ? Colors.orange
                  : Colors.red;
        });
      } else {
        setState(() {
          _ram = " Can't get RAM on Windows";
          color = Colors.red;
        });
      }
    } catch (e) {
      setState(() {
        _ram = " Can't get RAM";
        color = Colors.red;
      });
    }
  }

  showPrepromptAlert() async {
    var prePrompts = await getPrePrompts();
    showDialog(
      context: context,
      builder: (BuildContext contextAlert) {
        return AlertDialog(
          title: const Text("Pre-Prompt"),
          content: ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 300,
            ),
            child: SingleChildScrollView(
              child: ListBody(
                children: [
                  for (var prePrompt in prePrompts)
                    Wrap(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey,
                                width: 1,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.grey,
                                  blurRadius: 1,
                                ),
                              ],
                              color: Colors.white,
                            ),
                            child: ListTile(
                              title: Text(prePrompt,
                                  style: const TextStyle(
                                    color: Colors.black,
                                  )),
                              onTap: () {
                                setState(() {
                                  this.prePrompt = prePrompt;
                                });
                                SharedPreferences.getInstance().then((prefs) {
                                  prefs.setString(
                                      "defaultPrePrompt", prePrompt);
                                });
                                Navigator.of(contextAlert).pop();
                              },
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding: const EdgeInsets.all(0),
                                ),
                                onPressed: () {
                                  deletePrompt(prePrompt);
                                  Navigator.of(contextAlert).pop();
                                },
                                child: const Text(
                                  "X",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ElevatedButton(
                    onPressed: () async {
                      await addPrePromptAlert();
                      //save prePrompt in shared preferences
                      prePrompts.add(prePrompt);
                      Navigator.of(contextAlert).pop();
                    },
                    child: const Text("+",
                        style: TextStyle(
                          color: Colors.white,
                        )),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text("OK",
                  style: TextStyle(
                    color: Colors.cyan,
                  )),
              onPressed: () {
                setState(() {
                  prePrompt = promptController.text;
                });
                Navigator.of(contextAlert).pop();
              },
            ),
          ],
        );
      },
    );
  }

  addPrePromptAlert() {
    var prePromptController = TextEditingController();
    return showDialog(
      context: context,
      builder: (BuildContext contextAlert) {
        return AlertDialog(
          title: const Text("Add a new Pre-Prompt"),
          content: ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 300,
            ),
            child: SingleChildScrollView(
              child: ListBody(
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 200,
                    ),
                    child: TextField(
                      keyboardType: TextInputType.multiline,
                      maxLines: 3,
                      expands: false,
                      controller: prePromptController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelStyle: TextStyle(
                          color: Colors.cyan,
                        ),
                        labelText: 'New Pre-Prompt',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text(
                "OK",
                style: TextStyle(
                  color: Colors.cyan,
                ),
              ),
              onPressed: () async {
                setState(() {
                  prePrompt = prePromptController.text;
                });
                //save prePrompt in shared preferences
                var prePrompts = await getPrePrompts();
                prePrompts.add(prePrompt);
                var prefs = await SharedPreferences.getInstance();
                prefs.setStringList("prePrompts", prePrompts);
                Navigator.of(contextAlert).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<List<String>> getPrePrompts() async {
    var prefs = await SharedPreferences.getInstance();
    List<String>? prePrompts = [];
    if (prefs.containsKey("prePrompts")) {
      prePrompts = prefs.getStringList("prePrompts") ?? [];
    }
    return prePrompts;
  }

  void showSettings() {
    showDialog(
      context: context, 
      builder: (BuildContext contextAlert) {
        return AlertDialog(
          title: const Text("Settings"),
          content: ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 300,
            ),
            child: SingleChildScrollView(
              child: ListBody(
                children: [
                  const Text("RAM :"),
                  Text(
                    _ram,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      openFile();
                    },
                    child: const Text(
                      "Load Model",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void showInfosAlert() {
    showDialog(
      context: context,
      builder: (BuildContext contextAlert) {
        return AlertDialog(
          title: const Text("Infos"),
          content: ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 300,
            ),
            child: SingleChildScrollView(
              child: ListBody(
                children: [
                  const SelectableText(
                      "This app is a demo of the llama.cpp model.\n\n"
                      "You can find the source code of this app on GitHub\n\n"
                      'It was made on Flutter using an implementation of ggerganov/llama.cpp recompiled to work on mobiles\n\n'
                      'The LLaMA models are officially distributed by Meta and will never be provided by us\n\n'
                      'It was made by Maxime GUERIN and Thibaut LEAUX from the french company Bip-Rep based in Lyon (France)'),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(0),
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    onPressed: () async {
                      var url = 'https://bip-rep.com';
                      if (await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url));
                      } else {
                        throw 'Could not launch $url';
                      }
                    },
                    child: Image.asset(
                      "assets/biprep.jpg",
                      width: 100,
                      height: 100,
                    ),
                  ),
                ],
              ),
            ),
          )
        );
      },
    );
  }

  void deletePrompt(String prePrompt) async {
    var prefs = await SharedPreferences.getInstance();
    List<String>? prePrompts = [];
    if (prefs.containsKey("prePrompts")) {
      prePrompts = prefs.getStringList("prePrompts") ?? [];
    }
    prePrompts.remove(prePrompt);
    prefs.setStringList("prePrompts", prePrompts);
  }

  void initDefaultPrompts() async {
    var prefs = await SharedPreferences.getInstance();
    var prePrompts = await getPrePrompts();
    if (prePrompts.isEmpty) {
      await prefs.setStringList("prePrompts", defaultPrePrompts);
      prePrompts = defaultPrePrompts;
    }
    var defaultPrePrompt = prefs.getString("defaultPrePrompt");
    if (defaultPrePrompt != null) {
      prePrompt = defaultPrePrompt;
    } else if (prePrompts.isNotEmpty) {
      prePrompt = prePrompts[0];
    }
    setState(() {});
    if (prefs.containsKey("reversePrompt")) {
      reversePromptController.text = prefs.getString("reversePrompt") ?? "";
    } else {
      reversePromptController.text = 'User:';
    }
    reversePromptController.addListener(() {
      prefs.setString("reversePrompt", reversePromptController.text);
    });
  }

  void openFile() async {
    if (fileState != FileState.notFound) {
      await ModelFilePath.deleteModelFile();
      setState(() {
        fileState = FileState.notFound;
      });
    }
    
    setState(() {
      fileState = FileState.opening;
    });

    var filePath = await ModelFilePath.getFilePath(); // getting file path

    if (filePath == null) {
      print("file not found");
      setState(() {
        fileState = FileState.notFound;
      });
      return;
    }

    var file = File(filePath);
    if (!file.existsSync()) {
      print("file not found 2");
      setState(() {
        fileState = FileState.notFound;
      });
      await ModelFilePath.deleteModelFile();
      return;
    }

    setState(() {
      fileState = FileState.found;
    });
  }

  void deletePreprompt() {
    setState(() {
      prePrompt = "";
    });
  }

  void testFileExisting() async {
    if (Platform.isIOS) {
      (await SharedPreferences.getInstance()).remove('path');
    }
    var found = await ModelFilePath.filePathExists();
    if (found) {
      setState(() {
        fileState = FileState.found;
      });
    } else {
      setState(() {
        fileState = FileState.notFound;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade800,  // Set a solid color here
          ),
        ),
        title: GestureDetector(
          onTap: () {
            showInfosAlert();
          },
          child: Text(widget.title),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              showSettings();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.purple.shade900,
                  Colors.cyan.shade900,
                ],
              ),
            ),
          ),
          SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 700,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const SizedBox(
                        height: 20,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              showParams = !showParams;
                            });
                          },
                          child: const Icon(
                            Icons.settings,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (fileState == FileState.found) ...[
                        if (showParams) ...[
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    ElevatedButton(
                                        onPressed: showPrepromptAlert,
                                        child: const Text(
                                          "Pre-Prompt",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: SizedBox(
                                        width: 30,
                                        height: 30,
                                        child: ElevatedButton(
                                            onPressed: deletePreprompt,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              padding:
                                                  const EdgeInsets.all(0.0),
                                            ),
                                            child: const Text(
                                              "X",
                                              style: TextStyle(
                                                  color: Colors.white),
                                            )),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxHeight: 200,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: SingleChildScrollView(
                                            child: SelectableText(
                                              "Pre-Prompt : $prePrompt",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: TextField(
                                    keyboardType: TextInputType.multiline,
                                    maxLines: 1,
                                    expands: false,
                                    controller: reversePromptController,
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      labelStyle: const TextStyle(
                                        color: Colors.cyan,
                                      ),
                                      labelText: 'Reverse Prompt',
                                      suffixIcon: IconButton(
                                          onPressed: () {
                                            reversePromptController.clear();
                                          },
                                          icon: const Icon(Icons.clear)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton(
                              onPressed: toggleShowFineTune,
                              child: Text(
                                showParamsFineTune
                                    ? "Hide Params"
                                    : "Show Params",
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          if (showParamsFineTune)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.cyan),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    children: [
                                      const Text(
                                        "Once you start a conversation, you cannot change the params.",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: ElevatedButton(
                                          onPressed: () {
                                            paramsLlama.resetAll(setState);
                                          },
                                          child: const Text(
                                            "Reset All",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Wrap(
                                        children: [
                                          //ParamsLlama(),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                maxWidth: 150,
                                              ),
                                              child: Wrap(
                                                children: [
                                                  const Text(
                                                    'seed (-1 for random):',
                                                  ),
                                                  TextField(
                                                    controller: paramsLlama
                                                        .seedController,
                                                    keyboardType:
                                                        TextInputType.number,
                                                    decoration:
                                                        const InputDecoration(
                                                      hintText: 'seed',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                maxWidth: 150,
                                              ),
                                              child: Wrap(
                                                children: [
                                                  const Text(
                                                    'n_threads:',
                                                  ),
                                                  TextField(
                                                    controller: paramsLlama
                                                        .n_threadsController,
                                                    keyboardType:
                                                        TextInputType.number,
                                                    decoration:
                                                        const InputDecoration(
                                                      hintText: 'n_threads',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                maxWidth: 150,
                                              ),
                                              child: Wrap(
                                                children: [
                                                  const Text(
                                                    'n_predict:',
                                                  ),
                                                  TextField(
                                                    controller: paramsLlama
                                                        .n_predictController,
                                                    keyboardType:
                                                        TextInputType.number,
                                                    decoration:
                                                        const InputDecoration(
                                                      hintText: 'n_predict',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                maxWidth: 150,
                                              ),
                                              child: Wrap(
                                                children: [
                                                  const Text(
                                                    'repeat_last_n:',
                                                  ),
                                                  TextField(
                                                    controller: paramsLlama
                                                        .repeat_last_nController,
                                                    keyboardType:
                                                        TextInputType.number,
                                                    decoration:
                                                        const InputDecoration(
                                                      hintText: 'repeat_last_n',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                maxWidth: 150,
                                              ),
                                              child: Wrap(
                                                children: [
                                                  const Text(
                                                    'n_parts (-1 for auto):',
                                                  ),
                                                  TextField(
                                                    controller: paramsLlama
                                                        .n_partsController,
                                                    keyboardType:
                                                        TextInputType.number,
                                                    decoration:
                                                        const InputDecoration(
                                                      hintText: 'n_parts',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                maxWidth: 150,
                                              ),
                                              child: Wrap(
                                                children: [
                                                  const Text(
                                                    'n_ctx:',
                                                  ),
                                                  TextField(
                                                    controller: paramsLlama
                                                        .n_ctxController,
                                                    keyboardType:
                                                        TextInputType.number,
                                                    decoration:
                                                        const InputDecoration(
                                                      hintText: 'n_ctx',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                maxWidth: 150,
                                              ),
                                              child: Wrap(
                                                children: [
                                                  const Text(
                                                    'top_k:',
                                                  ),
                                                  TextField(
                                                    controller: paramsLlama
                                                        .top_kController,
                                                    keyboardType:
                                                        TextInputType.number,
                                                    decoration:
                                                        const InputDecoration(
                                                      hintText: 'top_k',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                maxWidth: 150,
                                              ),
                                              child: Wrap(
                                                children: [
                                                  const Text(
                                                    'top_p:',
                                                  ),
                                                  TextField(
                                                    controller: paramsLlama
                                                        .top_pController,
                                                    keyboardType:
                                                        TextInputType.number,
                                                    decoration:
                                                        const InputDecoration(
                                                      hintText: 'top_p',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                maxWidth: 150,
                                              ),
                                              child: Wrap(
                                                children: [
                                                  const Text(
                                                    'temp:',
                                                  ),
                                                  TextField(
                                                    controller: paramsLlama
                                                        .tempController,
                                                    keyboardType:
                                                        TextInputType.number,
                                                    decoration:
                                                        const InputDecoration(
                                                      hintText: 'temp',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                maxWidth: 150,
                                              ),
                                              child: Wrap(
                                                children: [
                                                  const Text(
                                                    'repeat_penalty:',
                                                  ),
                                                  TextField(
                                                    controller: paramsLlama
                                                        .repeat_penaltyController,
                                                    keyboardType:
                                                        TextInputType.number,
                                                    decoration:
                                                        const InputDecoration(
                                                      hintText:
                                                          'repeat_penalty',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                maxWidth: 150,
                                              ),
                                              child: Wrap(
                                                children: [
                                                  const Text(
                                                    'batch_size:',
                                                  ),
                                                  TextField(
                                                    controller: paramsLlama
                                                        .n_batchController,
                                                    keyboardType:
                                                        TextInputType.number,
                                                    decoration:
                                                        const InputDecoration(
                                                      hintText: 'batch_size',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                maxWidth: 150,
                                              ),
                                              child: Wrap(
                                                alignment: WrapAlignment.center,
                                                crossAxisAlignment:
                                                    WrapCrossAlignment.center,
                                                children: [
                                                  const Text(
                                                    'memory_f16:',
                                                  ),
                                                  Checkbox(
                                                      value: paramsLlama
                                                          .memory_f16,
                                                      onChanged: (value) {
                                                        setState(() {
                                                          paramsLlama
                                                                  .memory_f16 =
                                                              value!;
                                                        });
                                                        paramsLlama
                                                            .saveBoolToSharedPrefs(
                                                                'memory_f16',
                                                                value!);
                                                      }),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                maxWidth: 150,
                                              ),
                                              child: Wrap(
                                                alignment: WrapAlignment.center,
                                                crossAxisAlignment:
                                                    WrapCrossAlignment.center,
                                                children: [
                                                  const Text(
                                                    'random_prompt:',
                                                  ),
                                                  Checkbox(
                                                      value: paramsLlama
                                                          .random_prompt,
                                                      onChanged: (value) {
                                                        setState(() {
                                                          paramsLlama
                                                                  .random_prompt =
                                                              value!;
                                                        });
                                                        paramsLlama
                                                            .saveBoolToSharedPrefs(
                                                                'random_prompt',
                                                                value!);
                                                      }),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                maxWidth: 150,
                                              ),
                                              child: Wrap(
                                                alignment: WrapAlignment.center,
                                                crossAxisAlignment:
                                                    WrapCrossAlignment.center,
                                                children: [
                                                  const Text(
                                                    'interactive:',
                                                  ),
                                                  Checkbox(
                                                      value: paramsLlama
                                                          .interactive,
                                                      onChanged: (value) {
                                                        setState(() {
                                                          paramsLlama
                                                                  .interactive =
                                                              value!;
                                                        });
                                                        paramsLlama
                                                            .saveBoolToSharedPrefs(
                                                                'interactive',
                                                                value!);
                                                      }),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                maxWidth: 150,
                                              ),
                                              child: Wrap(
                                                alignment: WrapAlignment.center,
                                                crossAxisAlignment:
                                                    WrapCrossAlignment.center,
                                                children: [
                                                  const Text(
                                                    'interactive_start:',
                                                  ),
                                                  Checkbox(
                                                      value: paramsLlama
                                                          .interactive_start,
                                                      onChanged: (value) {
                                                        setState(() {
                                                          paramsLlama
                                                                  .interactive_start =
                                                              value!;
                                                        });
                                                        paramsLlama
                                                            .saveBoolToSharedPrefs(
                                                                'interactive_start',
                                                                value!);
                                                      }),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                maxWidth: 150,
                                              ),
                                              child: Wrap(
                                                alignment: WrapAlignment.center,
                                                crossAxisAlignment:
                                                    WrapCrossAlignment.center,
                                                children: [
                                                  const Text(
                                                    'instruct (Chat4all and Alpaca):',
                                                  ),
                                                  Checkbox(
                                                      value:
                                                          paramsLlama.instruct,
                                                      onChanged: (value) {
                                                        setState(() {
                                                          paramsLlama.instruct =
                                                              value!;
                                                        });
                                                        paramsLlama
                                                            .saveBoolToSharedPrefs(
                                                                'instruct',
                                                                value!);
                                                      }),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                maxWidth: 150,
                                              ),
                                              child: Wrap(
                                                alignment: WrapAlignment.center,
                                                crossAxisAlignment:
                                                    WrapCrossAlignment.center,
                                                children: [
                                                  const Text(
                                                    'ignore_eos:',
                                                  ),
                                                  Checkbox(
                                                      value: paramsLlama
                                                          .ignore_eos,
                                                      onChanged: (value) {
                                                        setState(() {
                                                          paramsLlama
                                                                  .ignore_eos =
                                                              value!;
                                                        });
                                                        paramsLlama
                                                            .saveBoolToSharedPrefs(
                                                                'ignore_eos',
                                                                value!);
                                                      }),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                maxWidth: 150,
                                              ),
                                              child: Wrap(
                                                alignment: WrapAlignment.center,
                                                crossAxisAlignment:
                                                    WrapCrossAlignment.center,
                                                children: [
                                                  const Text(
                                                    'perplexity:',
                                                  ),
                                                  Checkbox(
                                                      value: paramsLlama
                                                          .perplexity,
                                                      onChanged: (value) {
                                                        setState(() {
                                                          paramsLlama
                                                                  .perplexity =
                                                              value!;
                                                        });
                                                        paramsLlama
                                                            .saveBoolToSharedPrefs(
                                                                'perplexity',
                                                                value!);
                                                      }),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ElevatedButton(
                            onPressed: toggleShowLog,
                            child: Text(
                              showLog ? "Hide Log" : "Show Log",
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          if (showLog)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.cyan),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Column(
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 8.0),
                                      child: Text("Log"),
                                    ),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxHeight: 200,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: SingleChildScrollView(
                                          child: SizedBox(
                                            width: double.infinity,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color: Colors.black),
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                  color: Colors.black,
                                                ),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Text(
                                                    log,
                                                    style: const TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                        const Text(
                          "Chat now !",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Stack(
                          children: [
                            //top right button to copy the result
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                  maxHeight:
                                      MediaQuery.of(context).size.height - 200),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SingleChildScrollView(
                                  controller: _consoleScrollController,
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border:
                                              Border.all(color: Colors.black),
                                          borderRadius:
                                              BorderRadius.circular(5),
                                          color: Colors.black,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: SelectableText(
                                            result,
                                            style: const TextStyle(
                                                color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (result.isNotEmpty)
                              Positioned(
                                top: 12,
                                right: 8,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    shape: const CircleBorder(),
                                    padding: const EdgeInsets.all(0),
                                    backgroundColor:
                                        Colors.blueGrey.withOpacity(0.5),
                                  ),
                                  onPressed: () {
                                    Clipboard.setData(
                                        ClipboardData(text: result));
                                    //delete the toast if it is already present
                                    ScaffoldMessenger.of(context)
                                        .removeCurrentSnackBar();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text("Text copied to clipboard"),
                                      ),
                                    );
                                  },
                                  child: Icon(
                                    Icons.copy,
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            TextField(
                              keyboardType: TextInputType.multiline,
                              // maxLines: 3,
                              //on enter send the message
                              onSubmitted: (value) {
                                _exec();
                              },
                              expands: false,
                              controller: promptController,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelStyle: const TextStyle(
                                  color: Colors.cyan,
                                ),
                                labelText: 'Prompt',
                                suffixIcon: Padding(
                                  padding: const EdgeInsets.only(right: 4.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ElevatedButton(
                                        onPressed: (inProgress) ? null : _exec,
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 5, vertical: 5),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (!inProgress)
                                              const Icon(
                                                Icons.send_sharp,
                                                color: Colors.white,
                                              ),
                                            if (inProgress)
                                              const Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      if (canStop && inProgress)
                                        ElevatedButton(
                                          onPressed: _cancel,
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 5, vertical: 5),
                                          ),
                                          child: const Icon(
                                            Icons.stop,
                                            color: Colors.white,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}