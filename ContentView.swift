import SwiftUI
import LocalAuthentication

var context = LAContext()

struct ContentView: View{
    @State private var isUnlocked = false
    @State private var failedAuth = ""
    
    var body: some View{
        if isUnlocked{
            MainView()
        }
        else{
            ZStack{
                Color.black
                    .ignoresSafeArea()
                Circle()
                    .scale(2)
                    .foregroundColor(.gray.opacity(0.4))
                Circle()
                    .scale(1.7)
                    .foregroundColor(.gray.opacity(0.7))
                Circle()
                    .scale(1.35)
                    .foregroundColor(.gray)
                VStack{
                    Text("Passbook")
                        .font(.largeTitle)
                        .bold()
                        .padding()
                        .foregroundColor(.white.opacity(0.5))
                    Button(action: authenticate) {
                        Label("Login", systemImage: "applelogo").opacity(0.8)
                            .padding()
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .background(RoundedRectangle(cornerRadius: 15).foregroundColor(.black.opacity(0.5)))
                    }
                }
                Text(failedAuth)
                    .padding()
                    .foregroundColor(.red)
                    .opacity(failedAuth.isEmpty ? 0.0 : 1.0)
            }
        }
    }
    
    private func authenticate(){
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error){
            let reasoning = "Need Access to authenticate"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reasoning){ success, error in
                DispatchQueue.main.async {
                    if success{
                        isUnlocked = true
                        failedAuth = ""
                    }
                    else{
                        print(error?.localizedDescription ?? "error")
                        failedAuth = error?.localizedDescription ?? "error"
                    }
                }
            }
        }
        else{
            print("try again")
        }
    }
}


