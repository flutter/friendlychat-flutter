package io.flutter.example.friendlychat;

import android.content.Intent;
import android.os.Bundle;
import io.flutter.app.FlutterActivity;
import io.flutter.plugins.firebase.database.FirebaseDatabasePlugin;
import io.flutter.plugins.firebase.storage.FirebaseStoragePlugin;
import io.flutter.plugins.googlesignin.GoogleSignInPlugin;
import io.flutter.plugins.imagepicker.ImagePickerPlugin;

public class MainActivity extends FlutterActivity {
    private GoogleSignInPlugin googleSignIn;
    private ImagePickerPlugin imagePicker;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        FirebaseDatabasePlugin.register(this);
        FirebaseStoragePlugin.register(this);
        googleSignIn = GoogleSignInPlugin.register(this);
        imagePicker = ImagePickerPlugin.register(this);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        imagePicker.onActivityResult(requestCode, resultCode, data);
        googleSignIn.onActivityResult(requestCode, resultCode, data);
    }
}
