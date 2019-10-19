

import SwiftUI
import AVKit
import Photos

public class TonetimePermissions: ObservableObject {
    @Published var permissions: [TonetimePermission]
    init(permissionTypes : [TonetimePermissionType]){
        self.permissions = []
        for p in permissionTypes {
            self.permissions.append(PermissionDictionary[p]!)
        }
    }
}
public struct TonetimePermissionsCheck: View {
    var appName = "Your App Name"
    @Binding var permissionsGranted: Bool
    @ObservedObject var myPermissions: TonetimePermissions
    @Environment(\.presentationMode) var presentation

    
    public init(_ appName:String, _ permissions:[TonetimePermissionType], _  permissionsGranted:Binding<Bool>) {
        self.appName = appName
        self._permissionsGranted = permissionsGranted
        self.myPermissions = TonetimePermissions(permissionTypes: permissions)
    }
    public var body: some View {
        return NavigationView {
            List {
                Section(header: Text("Please enable the following to get started")) {
                    ForEach(self.myPermissions.permissions.indices){ idx in
                        HStack {
                            Image(systemName: self.myPermissions.permissions[idx].image).frame(width: 20, height: 20, alignment: .center)
                            VStack(alignment: .leading) {
                                Text(self.myPermissions.permissions[idx].name).font(.headline)
                                Text(self.myPermissions.permissions[idx].description).fontWeight(Font.Weight.light).font(.caption)
                            }.padding(5)
                            Spacer()
                            if self.myPermissions.permissions[idx].checkIfAuthorized() {
                                Image(systemName: "checkmark").frame(alignment: .center).frame(width:70)
                            }
                            else {
                                Button(action: {
                                    self.checkAuthorization(perm: self.myPermissions.permissions[idx])
                                }, label: {
                                    Text("Enable")
                                    .padding(4)
                                    .border(Color.blue, width: 1)
                                }).frame(width:70)
                            }
                        }
                    }
                }
            }
            .navigationBarTitle(Text(appName))
            .listStyle(GroupedListStyle())
            .onAppear() { self.updatePermissionGranted() }
        }
    }
    
    func checkAuthorization(perm:TonetimePermission) {
        perm.requestAuthorization() { result in
            switch result {
            case .success(_):
                DispatchQueue.main.async {
                    self.updatePermissionGranted()
                    self.myPermissions.objectWillChange.send()
                }
            case .failure(_):
                self.openSettings()
            }
        }
    }

    func openSettings() {
        DispatchQueue.main.async {
            let settingsURL = URL(string: UIApplication.openSettingsURLString)
            print("Make it here?")
            UIApplication.shared.open(settingsURL!, options: [:], completionHandler: nil)
        }
    }
    func updatePermissionGranted() {
        var granted = true
        for p in myPermissions.permissions {
            if p.checkIfAuthorized() == false {
                granted = false
            }
        }
        if granted==true {
            self.presentation.wrappedValue.dismiss()
        }
        self.permissionsGranted = granted
    }
}


public struct PermissionsCheck_Previews: PreviewProvider {
    public static var previews: some View {
        TonetimePermissionsCheck("Your Test App", [.camera,.library,.microphone], .constant(true))
    }
}

public enum TonetimePermissionType {
    case camera,microphone,library,audio,locationInUse
}
public struct TonetimePermission: Identifiable {
    public var id: TonetimePermissionType
    var name: String
    var description:String
    var image:String
    var requestAuthorization: (_ completionHandler: @escaping (Result<Int, TonetimePermissionRequest>) -> Void)  -> Void
    var checkIfAuthorized: ()  -> Bool
}

public enum TonetimePermissionRequest: Error {
    case denied
}
public let PermissionDictionary: [TonetimePermissionType: TonetimePermission]  = [
    TonetimePermissionType.camera :
        TonetimePermission(id: .camera, name: "Camera", description: "Requested to record your videos", image: "camera", requestAuthorization: { result in
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) in
                if granted == true {
                    result(.success(1))
                }
                else {
                    result(.failure(.denied))
                }
            })
        },
            checkIfAuthorized: {
                return AVCaptureDevice.authorizationStatus(for: AVMediaType.video) == AVAuthorizationStatus.authorized
        }),
    
    TonetimePermissionType.microphone : TonetimePermission(id: .microphone, name: "Microphone", description: "Requested to hear your voice", image: "mic",requestAuthorization: { result in
            AVAudioSession.sharedInstance().requestRecordPermission { (r) in
                 if r == true {
                    result(.success(1))
                }
                else {
                    result(.failure(.denied))
                }
            }
        },
        checkIfAuthorized: {
            return  AVAudioSession.sharedInstance().recordPermission == .granted
        }
    ),
    
    TonetimePermissionType.library : TonetimePermission(id: .library, name: "Photo Library", description: "Requested to save videos to Photo Library", image: "camera.on.rectangle",requestAuthorization: { result in
            PHPhotoLibrary.requestAuthorization({ (status: PHAuthorizationStatus) in
                if status == .authorized {
                    result(.success(1))
                }
                else {
                    result(.failure(.denied))
                }

            })
        },
        checkIfAuthorized: {
            return  PHPhotoLibrary.authorizationStatus() == .authorized
        }
    )
]
