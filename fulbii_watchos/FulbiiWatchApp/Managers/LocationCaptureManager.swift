import CoreLocation
import Foundation

final class LocationCaptureManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var gpsStatus: String = "debil"
    @Published var lastSample: PositionSample?

    private let locationManager = CLLocationManager()
    private var isCapturing = false
    private var onSample: ((PositionSample) -> Void)?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.activityType = .fitness
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5
    }

    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func start(onSample: @escaping (PositionSample) -> Void) {
        self.onSample = onSample
        isCapturing = true
        locationManager.startUpdatingLocation()
    }

    func stop() {
        isCapturing = false
        locationManager.stopUpdatingLocation()
        onSample = nil
    }

    func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isCapturing, let location = locations.last else { return }
        let sample = PositionSample(
            timestamp: Date(),
            lat: location.coordinate.latitude,
            lng: location.coordinate.longitude,
            horizontalAccuracy: max(0, location.horizontalAccuracy),
            speed: max(0, location.speed)
        )
        lastSample = sample
        gpsStatus = sample.horizontalAccuracy <= 20 ? "ok" : "debil"
        onSample?(sample)
    }

    func locationManager(_: CLLocationManager, didFailWithError _: Error) {
        gpsStatus = "debil"
    }
}
