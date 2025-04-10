import Foundation
import MapKit
import CoreLocation
import Combine
import SwiftUI
import Observation

/// NavigationManager handles all app-wide navigation and sheet presentation
final class NavigationManager: ObservableObject {
    // Navigation properties
    @Published var currentDestinationCoordinate: CLLocationCoordinate2D?
    @Published var route: MKRoute?
    
    // Enum to define all possible navigation destinations
    enum Destination: Hashable {
        case hunt(Hunt)
        case task(HuntTask)
        case barCrawl(BarCrawl)
        case barStop(BarStop)
        case user(User)
        case team(Team)
        case settings
        case nearby
        case map
        case taskCompletion(HuntTask)
        case barStopVisit(BarStop)
        case taskDetail(HuntTask)
        case nearbyLocations
        case huntDetail(Hunt)
        case barCrawlDetail(BarCrawl)
        case barStopDetail(BarStop)
        case teamDetail(Team)
        case userProfile(User)
        case dynamicChallenges
        case profile
        case notifications
        case leaderboard
        case calendar
        case friendsList
        case searchResults
        
        // Custom hash implementation to allow for Hashable conformance
        func hash(into hasher: inout Hasher) {
            switch self {
            case .hunt(let hunt):
                hasher.combine("hunt")
                hasher.combine(hunt.id)
            case .task(let task):
                hasher.combine("task")
                hasher.combine(task.id)
            case .barCrawl(let barCrawl):
                hasher.combine("barCrawl")
                hasher.combine(barCrawl.id)
            case .barStop(let barStop):
                hasher.combine("barStop")
                hasher.combine(barStop.id)
            case .user(let user):
                hasher.combine("user")
                hasher.combine(user.id)
            case .team(let team):
                hasher.combine("team")
                hasher.combine(team.id)
            case .settings:
                hasher.combine("settings")
            case .nearby:
                hasher.combine("nearby")
            case .map:
                hasher.combine("map")
            case .taskCompletion(let task):
                hasher.combine("taskCompletion")
                hasher.combine(task.id)
            case .barStopVisit(let barStop):
                hasher.combine("barStopVisit")
                hasher.combine(barStop.id)
            case .taskDetail(let task):
                hasher.combine("taskDetail")
                hasher.combine(task.id)
            case .nearbyLocations:
                hasher.combine("nearbyLocations")
            case .huntDetail(let hunt):
                hasher.combine("huntDetail")
                hasher.combine(hunt.id)
            case .barCrawlDetail(let barCrawl):
                hasher.combine("barCrawlDetail")
                hasher.combine(barCrawl.id)
            case .barStopDetail(let barStop):
                hasher.combine("barStopDetail")
                hasher.combine(barStop.id)
            case .teamDetail(let team):
                hasher.combine("teamDetail")
                hasher.combine(team.id)
            case .userProfile(let user):
                hasher.combine("userProfile")
                hasher.combine(user.id)
            case .dynamicChallenges:
                hasher.combine("dynamicChallenges")
            case .profile:
                hasher.combine("profile")
            case .notifications:
                hasher.combine("notifications")
            case .leaderboard:
                hasher.combine("leaderboard")
            case .calendar:
                hasher.combine("calendar")
            case .friendsList:
                hasher.combine("friendsList")
            case .searchResults:
                hasher.combine("searchResults")
            }
        }
        
        // Custom equality check for Hashable conformance
        static func == (lhs: Destination, rhs: Destination) -> Bool {
            switch (lhs, rhs) {
            case (.hunt(let lhunt), .hunt(let rhunt)):
                return lhunt.id == rhunt.id
            case (.task(let ltask), .task(let rtask)):
                return ltask.id == rtask.id
            case (.barCrawl(let lbarCrawl), .barCrawl(let rbarCrawl)):
                return lbarCrawl.id == rbarCrawl.id
            case (.barStop(let lbarStop), .barStop(let rbarStop)):
                return lbarStop.id == rbarStop.id
            case (.user(let luser), .user(let ruser)):
                return luser.id == ruser.id
            case (.team(let lteam), .team(let rteam)):
                return lteam.id == rteam.id
            case (.settings, .settings),
                 (.nearby, .nearby),
                 (.map, .map):
                return true
            case (.taskCompletion(let ltask), .taskCompletion(let rtask)):
                return ltask.id == rtask.id
            case (.barStopVisit(let lbarStop), .barStopVisit(let rbarStop)):
                return lbarStop.id == rbarStop.id
            case (.taskDetail(let ltask), .taskDetail(let rtask)):
                return ltask.id == rtask.id
            case (.nearbyLocations, .nearbyLocations),
                 (.dynamicChallenges, .dynamicChallenges):
                return true
            case (.notifications, .notifications),
                 (.leaderboard, .leaderboard),
                 (.calendar, .calendar),
                 (.friendsList, .friendsList),
                 (.searchResults, .searchResults):
                return true
            default:
                return false
            }
        }
    }
    
    // Enum for sheet presentations
    enum Sheet: Identifiable, Hashable {
        case createHunt
        case createBarCrawl
        case createTask(Hunt)
        case createBarStop(BarCrawl)
        case joinTeam
        case createTeam
        case huntCreator
        case barCrawlCreator
        case taskCreator(Hunt)
        case barStopCreator(BarCrawl)
        case huntDetail(Hunt)
        case barCrawlDetail(BarCrawl)
        case taskDetail(HuntTask)
        case barStopDetail(BarStop)
        case profile(User)
        case teamDetail(Team)
        case teamCreator
        case taskCompletion(HuntTask)
        case barStopVisit(BarStop)
        case searchFilter
        case settings
        
        var id: String {
            switch self {
            case .createHunt:
                return "createHunt"
            case .createBarCrawl:
                return "createBarCrawl"
            case .createTask(let hunt):
                return "createTask-\(hunt.id)"
            case .createBarStop(let barCrawl):
                return "createBarStop-\(barCrawl.id)"
            case .joinTeam:
                return "joinTeam"
            case .createTeam:
                return "createTeam"
            case .huntCreator:
                return "huntCreator"
            case .barCrawlCreator:
                return "barCrawlCreator"
            case .taskCreator(let hunt):
                return "taskCreator-\(hunt.id)"
            case .barStopCreator(let barCrawl):
                return "barStopCreator-\(barCrawl.id)"
            case .huntDetail(let hunt):
                return "huntDetail-\(hunt.id)"
            case .barCrawlDetail(let barCrawl):
                return "barCrawlDetail-\(barCrawl.id)"
            case .taskDetail(let task):
                return "taskDetail-\(task.id)"
            case .barStopDetail(let barStop):
                return "barStopDetail-\(barStop.id)"
            case .profile(let user):
                return "profile-\(user.id)"
            case .teamDetail(let team):
                return "teamDetail-\(team.id)"
            case .teamCreator:
                return "teamCreator"
            case .taskCompletion(let task):
                return "taskCompletion-\(task.id)"
            case .barStopVisit(let barStop):
                return "barStopVisit-\(barStop.id)"
            case .searchFilter:
                return "searchFilter"
            case .settings:
                return "settings"
            }
        }
        
        // Add Hashable conformance
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        // Add Equatable conformance
        static func == (lhs: Sheet, rhs: Sheet) -> Bool {
            return lhs.id == rhs.id
        }
    }
    
    // Main navigation path for the app
    @Published var path = NavigationPath()
    
    // Sheet presentation
    @Published var activeSheet: Sheet? = nil
    @Published var isSheetPresented = false
    
    // Fullscreen presentation
    @Published var fullscreenDestination: Destination? = nil
    @Published var isFullscreenPresented = false
    
    // Confirmation dialog presentation
    @Published var isConfirmationDialogPresented = false
    @Published var confirmationTitle = ""
    @Published var confirmationMessage = ""
    @Published var confirmationPrimaryAction: (() -> Void)?
    @Published var confirmationPrimaryActionTitle = ""
    @Published var confirmationDestructiveAction: (() -> Void)?
    @Published var confirmationDestructiveActionTitle = ""
    @Published var confirmationActions: [ConfirmationAction] = []
    
    // Alert presentation
    @Published var isAlertPresented = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var alertPrimaryAction: (() -> Void)?
    @Published var alertPrimaryActionTitle = ""
    @Published var alertSecondaryAction: (() -> Void)?
    @Published var alertSecondaryActionTitle = ""
    @Published var alertActions: [AlertAction] = []
    
    // Action sheet presentation
    var isActionSheetPresented = false
    var actionSheetTitle: String? = nil
    var actionSheetMessage: String? = nil
    var actionSheetButtons: [Alert.Button] = []
    
    // Init to avoid issues
    init() {
        // No initialization needed for stored properties
    }
    
    // Helper structs for action sheets and alerts
    struct ConfirmationAction: Identifiable {
        let id = UUID()
        let title: String
        let role: ButtonRole?
        let handler: () -> Void
    }
    
    struct AlertAction: Identifiable {
        let id = UUID()
        let title: String
        let role: ButtonRole?
        let handler: () -> Void
    }
    
    // MARK: - Navigation Methods
    
    func navigateToHunt(_ hunt: Hunt) {
        path.append(Destination.hunt(hunt))
    }
    
    func navigateToTask(_ task: HuntTask) {
        path.append(Destination.task(task))
    }
    
    func navigateToBarCrawl(_ barCrawl: BarCrawl) {
        path.append(Destination.barCrawl(barCrawl))
    }
    
    func navigateToBarStop(_ barStop: BarStop) {
        path.append(Destination.barStop(barStop))
    }
    
    func navigateToTeam(_ team: Team) {
        path.append(Destination.team(team))
    }
    
    func navigateToUser(_ user: User) {
        path.append(Destination.user(user))
    }
    
    func navigateToSettings() {
        path.append(Destination.settings)
    }
    
    func navigateToNearby() {
        path.append(Destination.nearby)
    }
    
    func navigateToMap() {
        path.append(Destination.map)
    }
    
    func navigateToTaskCompletion(_ task: HuntTask) {
        path.append(Destination.taskCompletion(task))
    }
    
    func navigateToBarStopVisit(_ barStop: BarStop) {
        path.append(Destination.barStopVisit(barStop))
    }
    
    func navigateToDynamicChallenges() {
        path.append(Destination.dynamicChallenges)
    }
    
    func navigateToTaskDetail(task: HuntTask) {
        path.append(Destination.taskDetail(task))
    }
    
    func navigateToNearbyLocations() {
        path.append(Destination.nearbyLocations)
    }
    
    func navigateToDestination(_ destination: Destination) {
        path.append(destination)
    }
    
    // MARK: - Sheet Presentation Methods
    
    func presentSheet(_ sheet: Sheet) {
        activeSheet = sheet
        isSheetPresented = true
    }
    
    func dismissSheet() {
        isSheetPresented = false
        // When sheet is dismissed, give time for the animation to complete
        // before setting activeSheet to nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.activeSheet = nil
        }
    }
    
    // MARK: - Fullscreen Presentation Methods
    
    func presentFullscreen(_ destination: Destination) {
        fullscreenDestination = destination
        isFullscreenPresented = true
    }
    
    func dismissFullscreen() {
        isFullscreenPresented = false
        // When fullscreen is dismissed, give time for the animation to complete
        // before setting fullscreenDestination to nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.fullscreenDestination = nil
        }
    }
    
    // MARK: - Confirmation Dialog Methods
    
    func presentConfirmation(title: String, message: String, actions: [ConfirmationAction]) {
        confirmationTitle = title
        confirmationMessage = message
        confirmationActions = actions
        isConfirmationDialogPresented = true
    }
    
    func presentConfirmationDialog(title: String, message: String, primaryAction: @escaping () -> Void, primaryActionTitle: String, destructiveAction: (() -> Void)? = nil, destructiveActionTitle: String = "") {
        confirmationTitle = title
        confirmationMessage = message
        confirmationPrimaryAction = primaryAction
        confirmationPrimaryActionTitle = primaryActionTitle
        confirmationDestructiveAction = destructiveAction
        confirmationDestructiveActionTitle = destructiveActionTitle
        isConfirmationDialogPresented = true
    }
    
    func dismissConfirmation() {
        isConfirmationDialogPresented = false
    }
    
    // MARK: - Alert Methods
    
    func presentAlert(title: String, message: String, actions: [AlertAction]) {
        alertTitle = title
        alertMessage = message
        alertActions = actions
        isAlertPresented = true
    }
    
    func presentSimpleAlert(title: String, message: String, primaryAction: @escaping () -> Void, primaryActionTitle: String, secondaryAction: (() -> Void)? = nil, secondaryActionTitle: String = "") {
        alertTitle = title
        alertMessage = message
        alertPrimaryAction = primaryAction
        alertPrimaryActionTitle = primaryActionTitle
        alertSecondaryAction = secondaryAction
        alertSecondaryActionTitle = secondaryActionTitle
        isAlertPresented = true
    }
    
    func dismissAlert() {
        isAlertPresented = false
    }
    
    // MARK: - Action Sheet Methods
    
    func presentActionSheet(title: String, message: String, buttons: [Alert.Button]) {
        actionSheetTitle = title
        actionSheetMessage = message
        actionSheetButtons = buttons
        isActionSheetPresented = true
    }
    
    func dismissActionSheet() {
        isActionSheetPresented = false
    }
    
    // MARK: - Navigation Control
    
    func goBack() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    func goToRoot() {
        path = NavigationPath()
    }
}

extension NavigationManager {
    @ViewBuilder
    func view(for destination: Destination) -> some View {
        switch destination {
        case .hunt(let hunt):
            HuntDetailView(hunt: hunt)
        case .task(let task):
            TaskDetailView(task: task)
        case .barCrawl(let barCrawl):
            BarCrawlDetailView(barCrawl: barCrawl)
        case .barStop(let barStop):
            BarStopDetailView(barStop: barStop)
        case .team(let team):
            TeamDetailView(team: team)
        case .user(let user):
            UserProfileView(user: user)
        case .taskCompletion(let task):
            TaskDetailView(task: task)
        case .barStopVisit(let barStop):
            BarStopDetailView(barStop: barStop)
        case .huntDetail(let hunt):
            HuntDetailView(hunt: hunt)
        case .barCrawlDetail(let barCrawl):
            BarCrawlDetailView(barCrawl: barCrawl)
        case .taskDetail(let task):
            TaskDetailView(task: task)
        case .barStopDetail(let barStop):
            BarStopDetailView(barStop: barStop)
        case .teamDetail(let team):
            TeamDetailView(team: team)
        case .userProfile(let user):
            UserProfileView(user: user)
        case .nearbyLocations:
            NearbyView()
        case .dynamicChallenges:
            DynamicChallengeView()
        case .profile:
            ProfileView()
        case .notifications:
            NotificationsView()
        case .leaderboard:
            LeaderboardView()
        case .calendar:
            CalendarView()
        case .friendsList:
            FriendsListView()
        case .searchResults:
            SearchResultsView()
        default:
            Text("View not implemented")
        }
    }
    
    @ViewBuilder
    func view(for sheet: Sheet) -> some View {
        switch sheet {
        case .createHunt:
            HuntCreatorView()
        case .createBarCrawl:
            BarCrawlCreatorView()
        case .createTask(let hunt):
            TaskCreatorView(hunt: hunt)
        case .createBarStop(let barCrawl):
            BarStopCreatorView(barCrawl: barCrawl)
        case .joinTeam:
            TeamJoinView()
        case .createTeam:
            TeamCreatorView()
        case .huntCreator:
            HuntCreatorView()
        case .barCrawlCreator:
            BarCrawlCreatorView()
        case .taskCreator(let hunt):
            TaskCreatorView(hunt: hunt)
        case .barStopCreator(let barCrawl):
            BarStopCreatorView(barCrawl: barCrawl)
        case .searchFilter:
            SearchFilterView()
        case .settings:
            SettingsView()
        default:
            Text("View not implemented")
        }
    }
} 