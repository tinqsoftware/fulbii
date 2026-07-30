import Foundation

#if canImport(HealthKit)
import HealthKit
#endif

final class WorkoutManager {
    #if canImport(HealthKit) && os(watchOS)
    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    #endif

    func startWorkoutIfPossible() {
        #if canImport(HealthKit) && os(watchOS)
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .soccer
        configuration.locationType = .outdoor

        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            session?.startActivity(with: Date())
        } catch {
            session = nil
        }
        #endif
    }

    func endWorkout() {
        #if canImport(HealthKit) && os(watchOS)
        session?.end()
        session = nil
        #endif
    }
}
