import Foundation
import HealthKit

final class WorkoutManager {
    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?

    func startWorkoutIfPossible() {
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
    }

    func endWorkout() {
        session?.end()
        session = nil
    }
}
