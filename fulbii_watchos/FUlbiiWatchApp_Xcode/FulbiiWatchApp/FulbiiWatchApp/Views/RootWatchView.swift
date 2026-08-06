import SwiftUI

struct RootWatchView: View {
    @StateObject private var vm = MatchSessionManager()

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
    }
}
