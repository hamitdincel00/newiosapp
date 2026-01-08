import SwiftUI

struct MainView: View {
    @State private var showSideMenu = false
    
    var body: some View {
        ZStack {
            BottomTabView(showSideMenu: $showSideMenu)
            
            // Side Menu Overlay
            SideMenuView(isShowing: $showSideMenu)
        }
    }
}

