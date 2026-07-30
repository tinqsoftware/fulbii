import SwiftUI

struct RootWatchView: View {
    @StateObject private var vm = MatchSessionManager()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack(alignment: .top) {
            NavigationView {
                if vm.activeSession != nil {
                    LiveMatchView(vm: vm)
                } else if vm.latestSummary != nil {
                    MatchSummaryView(vm: vm)
                } else {
                    PreMatchView(vm: vm)
                }
            }

            if let banner = vm.transientBannerText {
                EventConfirmationView(text: banner)
                    .padding(.horizontal, 10)
                    .padding(.top, 6)
            }
        }
        .onAppear {
            vm.onAppVisible()
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                vm.onAppVisible()
            }
        }
    }
}
