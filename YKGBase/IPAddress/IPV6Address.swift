//
//  IPV6Address.swift
//  hamnet
//
//  Created by hxj on 2021/1/1.
//

import Foundation


// Use lookup tables to massively improve the performance of converting IP addresses to strings.
fileprivate let lut = ["00","01","02","03","04","05","06","07","08","09","0a","0b","0c","0d","0e","0f",
                       "10","11","12","13","14","15","16","17","18","19","1a","1b","1c","1d","1e","1f",
                       "20","21","22","23","24","25","26","27","28","29","2a","2b","2c","2d","2e","2f",
                       "30","31","32","33","34","35","36","37","38","39","3a","3b","3c","3d","3e","3f",
                       "40","41","42","43","44","45","46","47","48","49","4a","4b","4c","4d","4e","4f",
                       "50","51","52","53","54","55","56","57","58","59","5a","5b","5c","5d","5e","5f",
                       "60","61","62","63","64","65","66","67","68","69","6a","6b","6c","6d","6e","6f",
                       "70","71","72","73","74","75","76","77","78","79","7a","7b","7c","7d","7e","7f",
                       "80","81","82","83","84","85","86","87","88","89","8a","8b","8c","8d","8e","8f",
                       "90","91","92","93","94","95","96","97","98","99","9a","9b","9c","9d","9e","9f",
                       "a0","a1","a2","a3","a4","a5","a6","a7","a8","a9","aa","ab","ac","ad","ae","af",
                       "b0","b1","b2","b3","b4","b5","b6","b7","b8","b9","ba","bb","bc","bd","be","bf",
                       "c0","c1","c2","c3","c4","c5","c6","c7","c8","c9","ca","cb","cc","cd","ce","cf",
                       "d0","d1","d2","d3","d4","d5","d6","d7","d8","d9","da","db","dc","dd","de","df",
                       "e0","e1","e2","e3","e4","e5","e6","e7","e8","e9","ea","eb","ec","ed","ee","ef",
                       "f0","f1","f2","f3","f4","f5","f6","f7","f8","f9","fa","fb","fc","fd","fe","ff"
                      ].map { Array($0.utf8) }
fileprivate let colon: UInt8 = 0x3A
fileprivate let zero: UInt8 = 0x30
fileprivate let nine: UInt8 = 0x39
fileprivate let dot: UInt8 = 0x2E
fileprivate let a: UInt8 = 0x61
fileprivate let f: UInt8 = 0x66
fileprivate let A: UInt8 = 0x41
fileprivate let F: UInt8 = 0x46


/// Represents an IP version 6 address.
///
/// Immutable and space efficient.
///
/// - Author: Andrew Dunn.
///
public struct IPv6Address: LosslessStringConvertible, Equatable {
    fileprivate let high, low: UInt64
    
    public static func ==(lhs: IPv6Address, rhs: IPv6Address) -> Bool {
        return  lhs.high == rhs.high && lhs.low == rhs.low
    }
    
    public init() {
        low = 0;
        high = 0;
    }
    
    /// Initialises a new instance with the given values.
    ///
    /// - Parameters:
    ///   - a: The *first* component of the IP address.
    ///   - b: The *second* component of the IP address.
    ///   - c: The *third* component of the IP address.
    ///   - d: The *fourth* component of the IP address.
    ///   - e: The *fifth* component of the IP address.
    ///   - f: The *sixth* component of the IP address.
    ///   - g: The *seventh* component of the IP address.
    ///   - h: The *eighth* component of the IP address.
    public init (parts a: UInt16, _ b: UInt16, _ c: UInt16, _ d: UInt16,
                     _ e: UInt16, _ f: UInt16, _ g: UInt16, _ h: UInt16) {
        high = UInt64(a.bigEndian) | (UInt64(b.bigEndian) << 16)
               | (UInt64(c.bigEndian) << 32) | (UInt64(d.bigEndian) << 48)
        low = UInt64(e.bigEndian) | (UInt64(f.bigEndian) << 16)
              | (UInt64(g.bigEndian) << 32) | (UInt64(h.bigEndian) << 48)
    }
    
    /// Intialises a new instance from a string representaion of an IPv6
    /// address.
    ///
    /// - Parameter str: A string representation of an IPv6 address. If the
    ///                  string is anything other than an IPv6 address, `nil`
    ///                  will be returned instead.
    public init?(_ str: String) {
        var segments: [UInt16] = []
        var zeroRunIndex: Int = -1
        var currentValue: UInt16 = 0
        var currentLength = 0
        var hasHex = false
        var wasColon = false
        var parsingQuad = false
        var segment: UInt64 = 0
        var hi: UInt64 = 0
        var lo: UInt64 = 0
        var power: UInt16 = 16
        var ipv4: UInt32 = 0
        var ipv4Shift: UInt32 = 0
        
        for c in str.utf8 {
            let val: UInt16
            if c >= zero && c <= nine {
                val = UInt16(c - zero)
                currentLength += 1
                wasColon = false
                currentValue *= power
                currentValue += val
            }
            else if c >= A && c <= F {
                val = UInt16(c - A + 10)
                currentLength += 1
                hasHex = true
                wasColon = false
                currentValue *= power
                currentValue += val
            }
            else if c >= a && c <= f /* a-f */ {
                val = UInt16(c - a + 10)
                currentLength += 1
                hasHex = true
                wasColon = false
                currentValue *= power
                currentValue += val
            }
            else if c == dot /* . */ {
                wasColon = false
                // A segment with hex characters cannot be a part of an IPv4 address.
                if hasHex {
                    return nil
                }
                if (currentLength == 0) {
                    // Part had no digits.
                    return nil
                }
                // The first part of the quad needs to be re-calculated, as it was originally parsed as hex.
                if !parsingQuad {
                    var newV: UInt16 = 0
                    if currentValue > 0x100 {
                        newV += ((currentValue & 0xF00) >> 8) * 100
                    }
                    if currentValue > 0x10 {
                        newV += ((currentValue & 0xF0) >> 4) * 10
                    }
                    newV += currentValue & 0xF
                    currentValue = newV
                    power = 10
                }
                if (currentValue > 255) {
                    // Part was too long.
                    return nil
                }
                parsingQuad = true
                hasHex = false
                
                ipv4 |= UInt32(currentValue) << ipv4Shift
                currentValue = 0
                ipv4Shift += 8
                if (ipv4Shift > 24) {
                    // Encountered too many points.
                    return nil
                }
                currentLength = 0
            }
            else if c == colon {
                if wasColon == true {
                    if zeroRunIndex >= 0 {
                        return nil
                    }
                    zeroRunIndex = Int(segment)
                    continue
                }
                if parsingQuad {
                    return nil
                }
                wasColon = true
                hasHex = false
                
                if (zeroRunIndex == -1) {
                    let shift: UInt64 = (segment & 0b11) << 4
                    // Same as dividing by 4.
                    if segment >> 2 == 0 {
                        hi |= UInt64(currentValue.bigEndian) << shift
                    } else {
                        lo |= UInt64(currentValue.bigEndian) << shift
                    }
                    segment += 1
                } else {
                    segments.append(currentValue.bigEndian)
                }
                currentValue = 0
                currentLength = 0
            } else {
                break
            }
        }
        if (parsingQuad) {
            if (ipv4Shift != 24) {
                // Not enough parts.
                return nil
            }
            if (currentLength == 0) {
                // No final part.
                return nil
            }
            if (currentValue > 255) {
                // Part was too long.
                return nil
            }
            ipv4 |= UInt32(currentValue) << 24
            
            if (zeroRunIndex == -1) {
                segment += 2
                lo |= UInt64(ipv4 & 0xFFFF_FFFF) << 32
            } else {
                segments.append(UInt16(ipv4 & 0xFFFF))
                segments.append(UInt16((ipv4 & 0xFFFF_0000) >> 16))
            }
            currentValue = 0
            currentLength = 0
        }

        if (!parsingQuad && zeroRunIndex == -1) {
            let shift: UInt64 = (segment & 0b11) << 4
            // Same as dividing by 4.
            if segment >> 2 == 0 {
                hi |= UInt64(UInt16(currentValue).bigEndian) << shift
            } else {
                lo |= UInt64(UInt16(currentValue).bigEndian) << shift
            }
            segment += 1
        } else if currentLength > 0 || segments.count > 0 {
            if currentLength > 0 {
                segments.append(UInt16(currentValue).bigEndian)
            }
            if Int(segment) + segments.count > 8 {
                return nil
            }
            
            segment = UInt64(8 - segments.count)
            for val in segments {
                let shift: UInt64 = (segment & 0b11) << 4
                // Same as dividing by 4.
                if segment >> 2 == 0 {
                    hi |= UInt64(val) << shift
                } else {
                    lo |= UInt64(val) << shift
                }
                segment += 1
            }
        } else if Int(segment) == zeroRunIndex {
            segment = 8
        }
        
        if segment != 8 {
            return nil
        }
        
        high = hi
        low = lo
    }
    
    /// Returns `true` if the IP address is an unspecified, if you listen on
    /// this address, your socket will listen on all addresses available.
    ///
    /// - Note: Equivalent to checking if the IP address is equal to
    ///         **::**.
    public var isUnspecified: Bool {
        return high == 0 && low == 0
    }

    /// Returns `true` if the IP address is a loopback address.
    ///
    /// - Note: Equivalent to checking if the IP address is **::1**.
    public var isLoopback: Bool {
        return high == 0 && low == 0x0100_0000_0000_0000
    }
    
    /// Returns `true` if the IP address is a global unicast address **(2000::/3)**.
    public var isUnicastGlobal: Bool {
        return (high & 0xE0) == 0x20
    }
    
    /// Returns `true` if the IP address is a unique local address **(fc00::/7)**.
    public var isUnicastUniqueLocal: Bool {
        return (high & 0xFE) == 0xFC
    }
    
    /// Returns `true` if the IP address is a unicast link-local address **(fe80::/10)**.
    public var isUnicastLinkLocal: Bool {
        return (high & 0xC0FF) == 0x80FE
    }
    
    /// Returns `true` if the IP address is a (deprecated) unicast site-local address **(fec0::/10)**.
    public var isUnicastSiteLocal: Bool {
        return (high & 0xC0FF) == 0xC0FE
    }
    
    /// Returns `true` if the IP address is a multicast address **(ff00::/8)**.
    public var isMulticast: Bool {
        return (high & 0xFF) == 0xFF
    }
    
    /// Returns `true` if the IP address is in the range reserved for use in documentation.
    public var isDocumentation: Bool {
        return (high & 0xFFFF_FFFF) == 0xb80d_0120
    }
    
    /// Returns a string representation of the IP address. Will display IPv4 compatible/mapped addresses
    /// correctly, and will truncate zeroes when possible.
    public var description: String {
        var segment: Int = 0
        var isZeroRun = false
        var zeroRunLength = 0
        var longestZeroRun = -1
        var currentZeroRun = -1
        var longestZeroRunLength = 0
        
        // First task is to find the longest zero-run.
        // First 64 bits are 0.
        if high == 0 {
            // These cases need special handlers to prevent them from being presented as IPv4 compatible.
            if low == 0 {
                return "::"
            }
            if low == 0x0100_0000_0000_0000 {
                return "::1"
            }
            
            // Check if this is an IPv4-compatible/mapped IPv6 address.
            let ipv4Check = low & 0x0000_0000_FFFF_FFFF
            if (ipv4Check == 0 || ipv4Check == 0xFFFF_0000) {
                // Use dotted quads to represent the IPv4 part.
                let ipv4 = IPv4Address(fromUInt32: UInt32(low >> 32))
                if (ipv4Check == 0) {
                    return "::\(ipv4.description)"
                }
                return "::ffff:\(ipv4.description)"
            }
            
            // Skip the first 4 segments.
            isZeroRun = true
            zeroRunLength = 4
            longestZeroRun = 0
            currentZeroRun = 0
            longestZeroRunLength = 4
            segment = 4
        }
        
        var segments: [Int] = [0,0,0,0,0,0,0,0]
        while segment < 8 {
            // Calculate which 16-bit word we should be handling. (x & 0b11) << 4, is equivalent to
            // (x % 4) * 16.
            let shift: UInt64 = UInt64(segment & 0b11) << 4
            let word: Int
            // Same as dividing by 4.
            if segment >> 2 == 0 {
                word = Int((high >> shift) & 0xFFFF)
            } else {
                word = Int((low >> shift) & 0xFFFF)
            }
            segments[segment] = Int(word)
            
            let isZero = (word == 0)
            
            if segment == 0 && isZero {
                // isZeroRun will be misconfigured if the first segment is a zero, so let's fix that.
                isZeroRun = true
                currentZeroRun = 0
            } else if segment != 0 && isZero != isZeroRun {
                zeroRunLength = 0
                isZeroRun = isZero
                if (isZero) {
                    currentZeroRun = segment
                }
            }
            
            if (isZero) {
                zeroRunLength += 1
                if zeroRunLength > longestZeroRunLength {
                    longestZeroRunLength = zeroRunLength
                    longestZeroRun = currentZeroRun
                }
            }
            
            segment += 1
        }
        
        // Max length is 45 chars for an IPv4-mapped IPv6 address, 1 extra byte for a terminating NUL.
        var out = [UInt8].init(repeating: 0, count: 46)
        var ptr = 0
        // Special handling for when the first output segment is the longest zero run.
        if (longestZeroRun == 0) && (longestZeroRunLength > 1) {
            out[ptr] = colon
            ptr += 1
        }
        var i = 0
        while i < 8 {
            if (longestZeroRun == i) && (longestZeroRunLength > 1) {
                out[ptr] = colon
                ptr += 1
                i += longestZeroRunLength
                continue
            }
            let word = segments[i]
            if word == 0 {
                out[ptr] = 0x30
                ptr += 1
            } else if word & 0xFF == 0 {
                let byte = word >> 8
                if byte >= 0x10 {
                    out[ptr] = lut[byte][0]
                    ptr += 1
                }
                out[ptr] = lut[byte][1]
                ptr += 1
            } else {
                let hi = word & 0xFF
                let lo = word >> 8
                if hi >= 0x10 {
                    out[ptr] = lut[hi][0]
                    ptr += 1
                }
                out[ptr] = lut[hi][1]
                ptr += 1
                out[ptr] = lut[lo][0]
                ptr += 1
                out[ptr] = lut[lo][1]
                ptr += 1
            }
            i += 1
            if i < 8 {
                out[ptr] = colon
                ptr += 1
            }
        }
        
        // Measured to be faster than String(decoding: out.prefix(ptr), as: UTF8.self)
        return String.init(cString: out)
    }
    
    /// Returns a quad of 32-bit unsigned ints representing the IP address.
    public var words: (UInt32, UInt32, UInt32, UInt32) {
        return (UInt32(high & 0xFFFFFFFF), UInt32((high & 0xFFFFFFFF_00000000) >> 32),
                UInt32(low & 0xFFFFFFFF), UInt32((low & 0xFFFFFFFF_00000000) >> 32))
    }
    
    /// Returns an array of octets representing the parts of the IP address.
    public var octets: [UInt8] {
        return [UInt8(high & 0xFF), UInt8((high >> 8) & 0xFF),
                UInt8((high >> 16) & 0xFF), UInt8((high >> 24) & 0xFF),
                UInt8((high >> 32) & 0xFF), UInt8((high >> 40) & 0xFF),
                UInt8((high >> 48) & 0xFF), UInt8(high >> 56),
                UInt8(low & 0xFF), UInt8((low >> 8) & 0xFF),
                UInt8((low >> 16) & 0xFF), UInt8((low >> 24) & 0xFF),
                UInt8((low >> 32) & 0xFF), UInt8((low >> 40) & 0xFF),
                UInt8((low >> 48) & 0xFF), UInt8(low >> 56)]
    }
    
    /// Returns an unspecified IP address.
    public static var any: IPv6Address {
        struct Static {
            static let anyAddress = IPv6Address.init()
        }
        return Static.anyAddress
    }
    
    /// Returns a representation of the IPv6 loopback address **::1**.
    public static var loopback: IPv6Address {
        struct Static {
            static let loopbackAddress = IPv6Address.init(parts: 0, 0, 0, 0, 0, 0, 0, 1)
        }
        return Static.loopbackAddress
    }
}
