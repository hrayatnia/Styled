//
//  Color.swift
//  Styled
//
//  Created by Farzad Sharbafian on 10/16/19.
//

import Foundation
import class UIKit.UIColor

// MARK:- StyledColor
/// Used to fetch color on runtime based on current Style
///
/// - Important: It's important to follow **dot.case** syntax while defining name of colors. e.g `primary`, `primary.lvl1`
/// in-order to let them be pattern-matched
///
/// - Note: In pattern-matching, matches with `pattern` if it is *prefix* of given `Color`. For more information see `~=`. You can
/// disable this behavior by setting `isPrefixMatchingEnabled` to `false`
///
/// Sample usage:
///
/// 	extension StyledColor {
/// 	    static let primary  = Self(named: "primary")
/// 	    static let primary1 = Self(named: "primary.lvl1")
/// 	    static let primary2 = Self(named: "primary.lvl2")
/// 	}
///
/// `StyledColor` uses custom pattern-matchin.  in the example given, `primary2` would match
/// with `primary` if it is checked before `primary2`:
///
///  	switch StyledColor.primary2 {
///  	case .primary: // Will match ✅
///  	case .primary2: // Will not match ❌
///  	}
///
/// And without `isPrefixMatchingEnabled`:
///
/// 	StyledColor.isPrefixMatchingEnabled = false
/// 	switch StyledColor.primary2 {
///  	case .primary: // Will not match ❌
///  	case .primary2: // Will match ✅
///  	}
///
/// - SeeAlso: `~=` method in this file
public struct StyledColor: Hashable, CustomStringConvertible ,ExpressibleByStringLiteral {
	/// A type that represents a `StyledColor` name
	public typealias StringLiteralType = String
	
	/// Allows pattern-matching operator (`~=`) to match `value` with `pattern` if `pattern` is prefix of `value`
	/// E.g: `primary.lvl1` can be matched with `primary`
	public static var isPrefixMatchingEnabled: Bool = true
	
	/// Initiates a `StyledColor` with given name, to be fetched later
	///
	/// - Note: Make sure to follow **dot.case** format for naming Colors
	///
	/// - Parameter named: Name of the color.
	public init(named name: String) {
		self.description = name
		lazyColor = nil
	}
	
	/// This type is used internally to manage transformations applied to current `StyledColor` before fetcing `UIColor`
	let lazyColor: LazyColor?
	
	/// Describes specification of `UIColor` that will be *fetched*/*generated*
	///
	///  - Note: `StyledColor`s with transformations will not be sent to `StyledColorScheme`s directly
	///
	///  Samples:
	///
	/// 	StyledColor(named: "primary")
	/// 	// description: "primary"
	/// 	StyledColor.blending(.primary, 0.30, .secondary)
	/// 	// description: "(primary(0.30),secondary(0.70))"
	/// 	StyledColor.primary.blend(with: .black)
	/// 	// description: "(primary(0.50),UIColor(0.00 0.00 0.00 0.00)(0.50))"
	/// 	StyledColor.opacity(0.9, of: .primary)
	/// 	// description: "primary(0.90)"
	/// 	StyledColor.primary.transform { $0 }
	/// 	// description:  "(t->primary)"
	///
	public let description: String
	
	/// Ease of use on defining `StyledColor` variables
	///
	/// 	extension StyledColor {
	/// 	    static let primary:   Self = "primary"
	/// 	    static let secondary: Self = "secondary"
	/// 	}
	///
	/// - Parameter value: `String`
	public init(stringLiteral value: Self.StringLiteralType) { self.init(named: value) }
	
	/// Enables the pattern-matcher (i.e switch-statement) to patch `primary.lvl1` with `primary` if `primary.lvl1` is not available
	/// in the switch-statement
	///
	/// - Parameter pattern: `StyledColor` to match as prefix of the current value
	/// - Parameter value: `StyledColor` given to find the best match for
	@inlinable public static func ~=(pattern: StyledColor, value: StyledColor) -> Bool {
		isPrefixMatchingEnabled ? value.description.hasPrefix(pattern.description) : value == pattern
	}
}

extension StyledColor {
	/// This type is used to support transformations on `StyledColor` like `Blend`
	struct LazyColor: Hashable, CustomStringConvertible {
		/// Is generated on `init`, to keep the type Hashable and hide `StyledColor` in order to let `StyledColor` hold `LazyColor` in its definition
		let colorHashValue: Int
		
		/// Describes current color that will be returned
		let colorDescription: String
		
		/// Describes current color that will be returned
		var description: String { colorDescription }
		
		/// Provides `UIColor` which can be backed by `StyledColor` or static `UIColor`
		let color: (_ scheme: StyledColorScheme) -> UIColor?
		
		/// Used internally to pre-calculate hashValue of Internal `color`
		private static func hashed<H: Hashable>(_ category: String, _ value: H) -> Int {
			var hasher = Hasher()
			hasher.combine(category)
			value.hash(into: &hasher)
			return hasher.finalize()
		}
		
		/// Will load `UIColor` from `StyledColor` when needed
		init(_ styledColor: StyledColor) {
			colorHashValue = Self.hashed("StyledColor", styledColor)
			colorDescription = styledColor.description
			color = { styledColor.resolve(from: $0) }
		}
		
		/// Will directly propagate given `UIColor` when needed
		init(_ uiColor: UIColor) {
			colorHashValue = Self.hashed("UIColor", uiColor)
			colorDescription = "\(uiColor.styledDescription)"
			color = { _ in uiColor }
		}
		
		/// Will use custom Provider to provide `UIColor` when needed
		/// - Parameter name: Will be used as `description` and inside hash-algorithms
		init(name: String, _ colorProvider: @escaping (_ scheme: StyledColorScheme) -> UIColor?) {
			colorHashValue = Self.hashed("ColorProvider", name)
			colorDescription = name
			color = colorProvider
		}
		
		/// - Returns: `hashValue` of given parameters when initializing `LazyColor`
		func hash(into hasher: inout Hasher) {
			hasher.combine(colorHashValue)
		}
		
		/// Is backed by `hashValue` comparision
		static func == (lhs: LazyColor, rhs: LazyColor) -> Bool { lhs.hashValue == rhs.hashValue }
	}
	
	/// This method is used internally to manage transformations (if any) and provide `UIColor`
	/// - Parameter scheme:A `StyledColorScheme` to fetch `UIColor` from
	func resolve(from scheme: StyledColorScheme) -> UIColor? {
		lazyColor?.color(scheme) ?? scheme.color(for: self)
	}
	
	/// Enables `StyledColor` to accept transformations
	/// - Parameter lazyColor: `LazyColor` instance
	init(lazyColor: LazyColor) {
		self.lazyColor = lazyColor
		self.description = lazyColor.colorDescription
	}
	
	/// Blends `self`  to the other `LazyColor` given
	///
	/// - Note: Colors will not be blended, if any of them provide `nil`
	///
	/// - Parameter perc: Amount to pour from `self`. will be clamped to `[`**0.0**, **1.0**`]`
	/// - Parameter to: Targeted `LazyColor`
	/// - Returns: `from * perc + to * (1 - perc)`
	func blend(_ perc: Double, _ to: LazyColor) -> StyledColor {
		let fromDesc = "\(self)(\(String(format: "%.2f", perc)))"
		let toDesc = "\(to)(\(String(format: "%.2f", 1 - perc)))"
		return .init(lazyColor: .init(name: "(\(fromDesc),\(toDesc))") { scheme in
			guard let fromUIColor = self.resolve(from: scheme) else { return to.color(scheme) }
			guard let toUIColor = to.color(scheme) else { return fromUIColor }
			return fromUIColor.blend(CGFloat(perc), with: toUIColor)
		})
	}
	
	/// Blends `self` to the other `StyeledColor` given
	///
	/// - Note: Colors will not be blended, if any of them provide `nil`
	///
	/// - Parameter perc: Amount to pour from `self`. will be clamped to `[`**0.0**, **1.0**`]`
	/// - Parameter to: Targeted `StyeledColor`
	/// - Returns: `from * perc + to * (1 - perc)`
	public func blend(_ perc: Double = 0.5, with to: StyledColor) -> StyledColor { blend(perc, .init(to)) }
	
	/// Blends `self` to the other `UIColor` given
	///
	/// - Note: Colors will not be blended, if any of them provide `nil`
	///
	/// - Parameter perc: Amount to pour from `self`. will be clamped to `[`**0.0**, **1.0**`]`
	/// - Parameter to: Targeted `UIColor`
	/// - Returns: `from * perc + to * (1 - perc)`
	public func blend(_ perc: Double = 0.5, with to: UIColor) -> StyledColor { blend(perc, .init(to)) }
	
	/// Blends two `StyledColor`s together with the amount given
	///
	/// - Note: Colors will not be blended, if any of them provide `nil`
	///
	/// - Parameter from: `StyledColor` to pour from
	/// - Parameter perc: Amount to pour from `self`. will be clamped to `[`**0.0**, **1.0**`]`
	/// - Parameter to: Targeted `StyeledColor`
	/// - Returns: `from * perc + to * (1 - perc)`
	public static func blending(_ from: StyledColor, _ perc: Double = 0.5, with to: StyledColor) -> StyledColor { from.blend(perc, with: to) }
	
	/// Blends a `StyledColor` and `UIColor` together with the amount given
	///
	/// - Note: Colors will not be blended, if any of them provide `nil`
	///
	/// - Parameter from: `StyledColor` to pour from
	/// - Parameter perc: Amount to pour from `self`. will be clamped to `[`**0.0**, **1.0**`]`
	/// - Parameter to: Targeted `UIColor`
	/// - Returns: `from * perc + to * (1 - perc)`
	public static func blending(_ from: StyledColor, _ perc: Double = 0.5, with to: UIColor) -> StyledColor { from .blend(perc, with: to) }
	
	/// Set's `opacity` level
	/// - Parameter perc: will be clamped to `[`**0.0**, **1.0**`]`
	/// - Returns: new instance of `self` with given `opacity`
	public func opacity(_ perc: Double) -> StyledColor {
		return .init(lazyColor: .init(name: "\(self)(\(String(format: "%.2f", perc)))") { scheme in
			self.resolve(from: scheme)?.withAlphaComponent(CGFloat(perc))
		})
	}
	
	/// Set's `opacity` level of the given `color`
	/// - Parameter perc: will be clamped to `[`**0.0**, **1.0**`]`
	/// - Parameter color: `StyledColor`
	/// - Returns: new instance of `color` with given `opacity`
	public static func opacity(_ perc: Double, of color: StyledColor) -> StyledColor { color.opacity(perc) }
	
	/// Applies custom transformations on the `UIColor`
	/// - Parameter name: This field is used to identify different transforms and enable equality check. **"t"** by default
	/// - Parameter transform: Apply transformation before providing the `UIColor`
	public func transform(named name: String = "t", _ transform: @escaping (UIColor) -> UIColor) -> StyledColor {
		return .init(lazyColor: .init(name: "(\(name)->\(self))", { scheme in
			guard let color = self.resolve(from: scheme) else { return nil }
			return transform(color)
		}))
	}
	
	/// Applies custom transformations on the `UIColor` fetched from `StyledColor`
	/// - Parameter styledColor: `StyledColor` to fetch
	/// - Parameter name: This field is used to identify different transforms and enable equality check. **"t"** by default
	/// - Parameter transform: Apply transformation before providing the `UIColor`
	public static func transforming(_ styledColor: StyledColor,
									named name: String = "t",
									_ transform: @escaping (UIColor) -> UIColor) -> StyledColor {
		styledColor.transform(named: name, transform)
	}
}

// MARK:- StyledColorScheme
/// Use this protocol to provide `UIColor` for `Styled`
///
/// Sample:
///
/// 	struct DarkColorScheme: StyledColorScheme {
/// 	    func color(for styledColor: StyledColor) -> UIColor? {
/// 	        switch styledColor {
/// 	        case .primary: // return primary color
/// 	        case .secondary: // return secondary color
/// 	        default: fatalError("New `StyledColor` detected: \(styledColor)")
/// 	        }
/// 	    }
/// 	}
///
public protocol StyledColorScheme {
	
	/// `Styled` will use this method to fetch `UIColor`
	///
	/// - Note: It's a good practice to let the application crash if the scheme doesn't responde to given `styledColor`
	///
	/// - Important: **Do not** call this method directly. use `UIColor.styled(_:)` instead.
	///
	/// Sample for `DarkColorScheme`:
	///
	/// 	struct DarkColorScheme: StyledColorScheme {
	/// 	    func color(for styledColor: StyledColor) -> UIColor? {
	/// 	        switch styledColor {
	/// 	        case .primary1: // return primary level1 color
	/// 	        case .primary2: // return primary level2 color
	/// 	        default: fatalError("Forgot to support primary itself")
	/// 	        }
	/// 	    }
	/// 	}
	///
	/// - Parameter styledColor: `StyledColor` type to fetch `UIColor` from current scheme
	func color(for styledColor: StyledColor) -> UIColor?
}

// MARK:- StyledAssetsCatalog
/// Will fetch `StyledColor`s from Assets Catalog
///
/// - Note: if `StyledColor.isPrefixMatchingEnabled` is `true`, in case of failure at loading `a.b.c.d` will look for `a.b.c`
/// and if `a.b.c` is failed to be loaded, will look for `a.b` and so on. Will return `nil` if nothing were found.
///
/// - SeeAlso: `StyledColor(named:,bundle:)`
@available(iOS 11, *)
public struct StyledAssetsCatalog: StyledColorScheme {
	
	/// - Note: **Do not** Call this method directly
	///
	/// - Parameter styledColor: `StyledColor`
	public func color(for styledColor: StyledColor) -> UIColor? { .named(styledColor.description, in: nil) }
}

extension StyledColor {
	/// Fetches `UIColor` from ColorAsset defined in given `Bundle`
	/// - Parameter name: Name of the color to look-up in Assets Catalog
	/// - Parameter bundle: `Bundle` to look into it's Assets
	/// - SeeAlso: `XcodeAssetsStyledColorScheme`
	@available(iOS 11, *)
	public init(named name: String, bundle: Bundle) {
		self.description = name
		self.lazyColor = .init(name: "Bundle") {
			$0.color(for: .init(named: name)) ?? UIColor.named(name, in: bundle)
		}
	}
}

// MARK: UIColor+Extensions
extension UIColor {
	
	/// Will look in the Assets catalog in given `Bundle` for the given color
	///
	/// - Note: if `StyledColor.isPrefixMatchingEnabled` is `true` will try all possbile variations
	///
	/// - Parameter styledColorName: `String` name of the `StyledColor` (mostly it's description"
	/// - Parameter bundle: `Bundle` to look into it's Assets Catalog
	@available(iOS 11, *)
	fileprivate static func named(_ styledColorName: String, in bundle: Bundle?) -> UIColor? {
		guard StyledColor.isPrefixMatchingEnabled else {
			return UIColor(named: styledColorName, in: bundle, compatibleWith: nil)
		}
		var name = styledColorName
		while name != "" {
			if let color = UIColor(named: name, in: bundle, compatibleWith: nil) { return color }
			name = name.split(separator: ".").dropLast().joined(separator: ".")
		}
		return nil
	}
	
	/// Returns a simple description for UIColor to use in `LazyColor`
	fileprivate var styledDescription: String {
		var color = (r: 0.0 as CGFloat, g: 0.0 as CGFloat, b: 0.0 as CGFloat, a: 0.0 as CGFloat)
		self.getRed(&color.r, green: &color.g, blue: &color.b, alpha: &color.a)
		let r = String(format: "%.2f", color.r)
		let g = String(format: "%.2f", color.g)
		let b = String(format: "%.2f", color.b)
		let a = String(format: "%.2f", color.a)
		return "UIColor(\(r) \(g) \(b) \(a))"
	}
	
	/// Will fetch `UIColor` defined in current `Styled.colorScheme`
	///
	/// - Parameter styledColor: `StyledColor`
	public static func styled(_ styledColor: StyledColor, from scheme: StyledColorScheme = Styled.colorScheme) -> UIColor? {
		styledColor.resolve(from: scheme)
	}
	
	/// Blends current color with the other one.
	///
	/// - Important: `perc` **1.0** means to omit other color while `perc` **0.0** means to omit current color
	///
	/// - Parameter perc: Will be clamped to `[`**0.0**, **1.0**`]`
	/// - Parameter color: other `UIColor` to blend with. (Passing `.clear` will decrease opacity)
	public func blend(_ perc: CGFloat = 0.5, with color: UIColor) -> UIColor {
		let perc = min(max(0.0, perc), 1.0)
		var col1 = (r: 0.0 as CGFloat, g: 0.0 as CGFloat, b: 0.0 as CGFloat, a: 0.0 as CGFloat)
		var col2 = (r: 0.0 as CGFloat, g: 0.0 as CGFloat, b: 0.0 as CGFloat, a: 0.0 as CGFloat)
		
		self.getRed(&col1.r, green: &col1.g, blue: &col1.b, alpha: &col1.a)
		color.getRed(&col2.r, green: &col2.g, blue: &col2.b, alpha: &col2.a)
		
		let percComp = 1 - perc
		
		return UIColor(red:   col1.r * perc + col2.r * percComp,
					   green: col1.g * perc + col2.g * percComp,
					   blue:  col1.b * perc + col2.b * percComp,
					   alpha: col1.a * perc + col2.a * percComp)
	}
}
