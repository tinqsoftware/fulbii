import CoreLocation
import Foundation

struct HeatmapProjector {
    func projectedPoints(samples: [PositionSample], field: Field, geometry: FieldGeometry?) -> [FieldProjectedPoint] {
        guard let geometry else {
            return normalizeRaw(samples: samples)
        }

        return samples.map { sample in
            let meters = relativeMeters(from: sample.location, field: field)
            let rotated = rotate(point: meters, degrees: -geometry.rotationDegrees)
            let nx = max(0, min(1, (rotated.x + geometry.widthMeters / 2) / geometry.widthMeters))
            let ny = max(0, min(1, (rotated.y + geometry.lengthMeters / 2) / geometry.lengthMeters))
            return FieldProjectedPoint(x: nx, y: ny)
        }
    }

    private func normalizeRaw(samples: [PositionSample]) -> [FieldProjectedPoint] {
        guard let minLat = samples.map(\.lat).min(),
              let maxLat = samples.map(\.lat).max(),
              let minLng = samples.map(\.lng).min(),
              let maxLng = samples.map(\.lng).max(),
              maxLat > minLat,
              maxLng > minLng
        else {
            return samples.enumerated().map { index, _ in
                let denominator = max(1, samples.count - 1)
                return FieldProjectedPoint(x: Double(index) / Double(denominator), y: Double(index) / Double(denominator))
            }
        }

        return samples.map { sample in
            let nx = (sample.lng - minLng) / (maxLng - minLng)
            let ny = (sample.lat - minLat) / (maxLat - minLat)
            return FieldProjectedPoint(x: nx, y: ny)
        }
    }

    private func relativeMeters(from point: CLLocationCoordinate2D, field: Field) -> (x: Double, y: Double) {
        let center = CLLocation(latitude: field.centerLat, longitude: field.centerLng)
        let east = CLLocation(latitude: field.centerLat, longitude: point.longitude)
        let north = CLLocation(latitude: point.latitude, longitude: field.centerLng)

        let x = center.distance(from: east) * (point.longitude >= field.centerLng ? 1 : -1)
        let y = center.distance(from: north) * (point.latitude >= field.centerLat ? 1 : -1)
        return (x, y)
    }

    private func rotate(point: (x: Double, y: Double), degrees: Double) -> (x: Double, y: Double) {
        let radians = degrees * .pi / 180
        let cosA = cos(radians)
        let sinA = sin(radians)
        return (
            x: point.x * cosA - point.y * sinA,
            y: point.x * sinA + point.y * cosA
        )
    }
}
