import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:json_response_admin/api_entity.dart';
import 'package:json_response_admin/space_header.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Json Response',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
      builder: EasyLoading.init(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<ApiEntity> apis = [];
  EasyRefreshController refreshController = EasyRefreshController();
  String basePath = 'https://api.korat.work/call/';
  TextEditingController nameController = TextEditingController();
  TextEditingController bodyController = TextEditingController();
  List<String> apiTypes = ["GET", "POST"];
  String selectedApiTypes = '';

  @override
  void initState() {
    super.initState();
    selectedApiTypes = apiTypes[0];
  }

  void _delete(String name, String key) {
    showDialog(
      context: context,
      builder: (buildContext) {
        return AlertDialog(
          title: Text("Will delete <$name>?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(buildContext).pop();
              },
              child: const Text(
                "Cancel",
              ),
            ),
            TextButton(
              onPressed: () {
                _deleteApi(key, buildContext);
              },
              child: const Text(
                "Delete",
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteApi(
    String apiKey,
    BuildContext buildContext,
  ) {
    EasyLoading.show(status: 'loading...');
    Dio()
        .delete(
      "https://api.korat.work/delete/$apiKey",
    )
        .then((value) {
      EasyLoading.dismiss();
      Navigator.of(buildContext).pop();
      refreshController.callRefresh();
    }, onError: (_) {
      EasyLoading.dismiss();
    });
  }

  void _showCreateOrEditDialog(
    String apiKey,
    String apiName,
    String apiBody,
    String apiType,
  ) {
    nameController.text = apiName;
    bodyController.text = Uri.decodeComponent(
      apiBody,
    );
    showDialog(
      context: context,
      builder: (buildContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        hintText: "Name",
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: TextField(
                      maxLines: 10,
                      keyboardType: TextInputType.multiline,
                      controller: bodyController,
                      decoration: const InputDecoration(
                        hintText: "Response body",
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: DropdownButton<String>(
                          items: apiTypes
                              .map((item) => DropdownMenuItem(
                                    child: Text(
                                      item,
                                    ),
                                    value: item,
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              apiType = value!;
                            });
                          },
                          value: apiType,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(buildContext).pop();
                          },
                          child: const Text(
                            "Cancel",
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 20,
                        ),
                        TextButton(
                          onPressed: () {
                            if (apiKey.isEmpty) {
                              _createNewApi(
                                apiType,
                                nameController.text,
                                bodyController.text,
                                context,
                              );
                            } else {
                              _editApi(
                                apiKey,
                                apiType,
                                nameController.text,
                                bodyController.text,
                                context,
                              );
                            }
                          },
                          child: Text(
                            apiKey.isEmpty ? "Create API" : "Update API",
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _createNew() {
    _showCreateOrEditDialog(
      "",
      "",
      "",
      apiTypes[0],
    );
  }

  void _edit(ApiEntity apiEntity) {
    _showCreateOrEditDialog(
      apiEntity.apiKey,
      apiEntity.apiName,
      apiEntity.apiBody,
      apiEntity.apiType,
    );
  }

  void _createNewApi(
    String apiType,
    String apiName,
    String apiBody,
    BuildContext buildContext,
  ) {
    EasyLoading.show(status: 'loading...');
    Dio()
        .post(
      "https://api.korat.work/create_api/$apiType/$apiName",
      data: apiBody,
    )
        .then((value) {
      EasyLoading.dismiss();
      Navigator.of(buildContext).pop();
      refreshController.callRefresh();
    }, onError: (_) {
      EasyLoading.dismiss();
    });
  }

  void _editApi(
    String apiKey,
    String apiType,
    String apiName,
    String apiBody,
    BuildContext buildContext,
  ) {
    EasyLoading.show(status: 'loading...');
    Dio()
        .post(
      "https://api.korat.work/edit/$apiKey/$apiType/$apiName",
      data: apiBody,
    )
        .then((value) {
      EasyLoading.dismiss();
      Navigator.of(buildContext).pop();
      refreshController.callRefresh();
    }, onError: (_) {
      EasyLoading.dismiss();
    });
  }

  Future<void> _onRefresh() async {
    var response = await Dio().get('https://api.korat.work/list_api');
    apis.clear();
    var count = response.data['_count'];
    if (count > 0) {
      for (var item in response.data['_items']) {
        var apiEntity = ApiEntity();
        apiEntity.apiBody = item['api_body'];
        apiEntity.apiKey = item['key'];
        apiEntity.apiType = item['api_type'];
        apiEntity.apiName = item['api_name'];
        apis.add(apiEntity);
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Json Response Admin'),
        actions: [
          IconButton(
            onPressed: () {
              refreshController.callRefresh();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: EasyRefresh.custom(
        controller: refreshController,
        firstRefresh: true,
        header: SpaceHeader(),
        onRefresh: () async {
          await _onRefresh();
        },
        slivers: <Widget>[
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: ListTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          apis[index].apiName,
                          style: const TextStyle(
                            fontSize: 20,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: "Edit",
                              onPressed: () {
                                _edit(apis[index]);
                              },
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.blue,
                              ),
                            ),
                            IconButton(
                              tooltip: "Delete",
                              onPressed: () {
                                _delete(
                                    apis[index].apiName, apis[index].apiKey);
                              },
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                apis[index].apiType.toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(
                                width: 8,
                              ),
                              Text(
                                basePath + apis[index].apiKey,
                                style: const TextStyle(
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(
                                width: 8,
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.copy,
                                  color: Colors.blue,
                                  size: 20.0,
                                ),
                                tooltip: "Copy Url",
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(
                                      text: basePath + apis[index].apiKey,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: 0.5,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    Uri.decodeComponent(
                                      apis[index].apiBody,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: apis.length,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNew,
        tooltip: 'Create New Api',
        child: const Icon(Icons.add),
      ),
    );
  }
}
