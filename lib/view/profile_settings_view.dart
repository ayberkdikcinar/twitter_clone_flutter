import 'package:endower/core/localization/strings.dart';
import 'package:endower/viewmodel/profile_setting_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../bases/view_statefull_base.dart';
import '../core/components/custom_textFormField_widget.dart';
import '../core/components/custom_text_button_widget.dart';
import '../viewmodel/auth_viewmodel.dart';

class ProfileSettingView extends StatefulWidget {
  ProfileSettingView({Key key}) : super(key: key);

  @override
  _ProfileSettingViewState createState() => _ProfileSettingViewState();
}

class _ProfileSettingViewState extends StatefullBase<ProfileSettingView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    final _authUser = Provider.of<AuthViewModel>(context).user;
    final _profileSettings = Provider.of<ProfileSettingsViewModel>(context);
    _profileSettings.setUserId(_authUser.id);
    return Scaffold(
      appBar: AppBar(
        title: Text(ApplicationStrings.instance.editProfile),
        actions: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: CustomTextButton(
              backgroundColor: Theme.of(context).cardColor,
              onPressed: () => updateUserInfos(),
              text: ApplicationStrings.instance.save,
            ),
          )
        ],
      ),
      body: Form(
          key: _formKey,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      showModalBottom();
                    },
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage:
                          _profileSettings.image == null ? NetworkImage(Provider.of<AuthViewModel>(context).user.photo) : FileImage(_profileSettings.image),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.all(10),
                    height: dynamicHeight(0.05),
                    width: dynamicWidth(0.5),
                    child: CustomTextFormField(
                        borderRadious: 0,
                        labelText: 'Name',
                        initialVal: _authUser.name,
                        onChanged: (value) => {
                              _profileSettings.setname(value),
                            }),
                  ),
                  Container(
                    margin: EdgeInsets.all(10),
                    height: dynamicHeight(0.05),
                    width: dynamicWidth(0.5),
                    child: CustomTextFormField(
                        borderRadious: 0,
                        labelText: 'Username',
                        initialVal: _authUser.username,
                        onChanged: (value) => {
                              _profileSettings.setUsername(value),
                            }),
                  ),
                  Container(
                    margin: EdgeInsets.all(10),
                    width: dynamicWidth(0.5),
                    child: CustomTextFormField(
                      borderRadious: 0,
                      maxLines: 3,
                      labelText: 'Personal Informations',
                    ),
                  ),
                ],
              ),
            ),
          )),
    );
  }

  Future<void> updateUserInfos() async {
    var _response = await Provider.of<ProfileSettingsViewModel>(context, listen: false).saveChanges();
    if (!_response) {
      ScaffoldMessenger.of(context).showSnackBar(buildSnackBar(text: 'Username is already in use', second: 2));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(buildSnackBar(text: 'Your informations succesfully changed', second: 2, bgColor: Colors.green));
      Navigator.pop(context);
    }
  }

  showModalBottom() {
    final _profileSettings = Provider.of<ProfileSettingsViewModel>(context, listen: false);
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_enhance),
                onTap: () {
                  _profileSettings.photoFrom(ImageSource.camera).whenComplete(() => Navigator.of(context).pop());
                },
                title: Text('Catch a photo from camera'),
              ),
              ListTile(
                leading: Icon(Icons.photo_album),
                onTap: () {
                  _profileSettings.photoFrom(ImageSource.gallery).whenComplete(() => Navigator.of(context).pop());
                },
                title: Text('Upload image from gallery'),
              ),
            ],
          ),
        );
      },
    );
  }
}
