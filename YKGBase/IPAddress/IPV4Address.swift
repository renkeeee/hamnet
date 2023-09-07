//
//  IPV4Address.swift
//  hamnet
//
//  Created by hxj on 2021/1/1.
//

import Foundation

fileprivate let zero = UnicodeScalar("0")
fileprivate let nine = UnicodeScalar("9")
fileprivate let dot = UnicodeScalar(".")

// Use lookup tables to massively improve the performance of converting IP addresses to strings.
fileprivate let firstQuad = [  "0",  "1",  "2",  "3",  "4",  "5",  "6",  "7",  "8",  "9",
                              "10", "11", "12", "13", "14", "15", "16", "17", "18", "19",
                              "20", "21", "22", "23", "24", "25", "26", "27", "28", "29",
                              "30", "31", "32", "33", "34", "35", "36", "37", "38", "39",
                              "40", "41", "42", "43", "44", "45", "46", "47", "48", "49",
                              "50", "51", "52", "53", "54", "55", "56", "57", "58", "59",
                              "60", "61", "62", "63", "64", "65", "66", "67", "68", "69",
                              "70", "71", "72", "73", "74", "75", "76", "77", "78", "79",
                              "80", "81", "82", "83", "84", "85", "86", "87", "88", "89",
                              "90", "91", "92", "93", "94", "95", "96", "97", "98", "99",
                             "100","101","102","103","104","105","106","107","108","109",
                             "110","111","112","113","114","115","116","117","118","119",
                             "120","121","122","123","124","125","126","127","128","129",
                             "130","131","132","133","134","135","136","137","138","139",
                             "140","141","142","143","144","145","146","147","148","149",
                             "150","151","152","153","154","155","156","157","158","159",
                             "160","161","162","163","164","165","166","167","168","169",
                             "170","171","172","173","174","175","176","177","178","179",
                             "180","181","182","183","184","185","186","187","188","189",
                             "190","191","192","193","194","195","196","197","198","199",
                             "200","201","202","203","204","205","206","207","208","209",
                             "210","211","212","213","214","215","216","217","218","219",
                             "220","221","222","223","224","225","226","227","228","229",
                             "230","231","232","233","234","235","236","237","238","239",
                             "240","241","242","243","244","245","246","247","248","249",
                             "250","251","252","253","254","255"]
fileprivate let latterQuads = [  ".0",  ".1",  ".2",  ".3",  ".4",  ".5",  ".6",  ".7",  ".8",  ".9",
                                ".10", ".11", ".12", ".13", ".14", ".15", ".16", ".17", ".18", ".19",
                                ".20", ".21", ".22", ".23", ".24", ".25", ".26", ".27", ".28", ".29",
                                ".30", ".31", ".32", ".33", ".34", ".35", ".36", ".37", ".38", ".39",
                                ".40", ".41", ".42", ".43", ".44", ".45", ".46", ".47", ".48", ".49",
                                ".50", ".51", ".52", ".53", ".54", ".55", ".56", ".57", ".58", ".59",
                                ".60", ".61", ".62", ".63", ".64", ".65", ".66", ".67", ".68", ".69",
                                ".70", ".71", ".72", ".73", ".74", ".75", ".76", ".77", ".78", ".79",
                                ".80", ".81", ".82", ".83", ".84", ".85", ".86", ".87", ".88", ".89",
                                ".90", ".91", ".92", ".93", ".94", ".95", ".96", ".97", ".98", ".99",
                               ".100",".101",".102",".103",".104",".105",".106",".107",".108",".109",
                               ".110",".111",".112",".113",".114",".115",".116",".117",".118",".119",
                               ".120",".121",".122",".123",".124",".125",".126",".127",".128",".129",
                               ".130",".131",".132",".133",".134",".135",".136",".137",".138",".139",
                               ".140",".141",".142",".143",".144",".145",".146",".147",".148",".149",
                               ".150",".151",".152",".153",".154",".155",".156",".157",".158",".159",
                               ".160",".161",".162",".163",".164",".165",".166",".167",".168",".169",
                               ".170",".171",".172",".173",".174",".175",".176",".177",".178",".179",
                               ".180",".181",".182",".183",".184",".185",".186",".187",".188",".189",
                               ".190",".191",".192",".193",".194",".195",".196",".197",".198",".199",
                               ".200",".201",".202",".203",".204",".205",".206",".207",".208",".209",
                               ".210",".211",".212",".213",".214",".215",".216",".217",".218",".219",
                               ".220",".221",".222",".223",".224",".225",".226",".227",".228",".229",
                               ".230",".231",".232",".233",".234",".235",".236",".237",".238",".239",
                               ".240",".241",".242",".243",".244",".245",".246",".247",".248",".249",
                               ".250",".251",".252",".253",".254",".255"
                              ]

/// Represents an IP version 4 address.
///
/// Immutable and space efficient.
///
/// - Author: Andrew Dunn.
///
public struct IPv4Address: LosslessStringConvertible, Equatable {
    // Store the value in an array to enable simple typecasting to an array of
    // [UInt8] values.
    fileprivate let value: UInt32;
    
    /// Initialises a new instance with all zeroes.
    public init () {
        value = 0
    }
    
    /// Initialises a new instance with the given values.
    ///
    /// - Parameters:
    ///   - a: The *first* component of the IP address.
    ///   - b: The *second* component of the IP address.
    ///   - c: The *third* component of the IP address.
    ///   - d: The *fourth & final* component of the IP address.
    public init (parts a: UInt8, _ b: UInt8, _ c: UInt8, _ d: UInt8) {
        value = UInt32(a) | UInt32(b) << 8 | UInt32(c) << 16 | UInt32(d) << 24
    }
    
    /// Initialises a new instance with an array of octets.
    ///
    /// - Parameter array: An array of octets that make up the parts of an IP
    ///                    address.
    ///
    /// - Note: If the number of elements in the array is not equal to *4*,
    ///         the behaviour is undefined.
    public init (fromOctets array: [UInt8]) {
        assert(array.count == 4)
        value = array.withUnsafeBytes({ (p) -> UInt32 in
            return p.load(as: UInt32.self)
        })
    }
    
    /// Intialises a new instance with an integer representation of an IP
    /// address in network-byte order.
    ///
    /// - Parameter uint: An integer representation of an IP address in
    ///                   network-byte order.
    public init (fromUInt32 uint: UInt32) {
        value = uint
    }
    
    /// Intialises a new instance from a string representaion of an IPv4
    /// address.
    ///
    /// - Parameter str: A string representation of an IPv4 address. If the
    ///                  string is anything other than an IPv4 address, `nil`
    ///                  will be returned instead.
    public init? (_ str: String) {
        var shiftedDistance = UInt32(0)
        var currentValue = UInt32(0)
        var currentLength = 0
        var rawValue = UInt32(0)
        for c in str.unicodeScalars {
            // Handle digits.
            if c >= zero && c <= nine {
                currentValue *= 10
                currentLength += 1
                if (currentLength > 3) {
                    // Part was too long.
                    return nil
                }
                currentValue += c.value - zero.value
            } else if c == dot {
                if (currentLength == 0) {
                    // Part had no digits.
                    return nil
                }
                currentLength = 0
                if (currentValue > 255) {
                    // Part was too long.
                    return nil
                }
                rawValue |= currentValue << shiftedDistance
                currentValue = 0
                shiftedDistance += 8
                if (shiftedDistance > 24) {
                    // Encountered too many points.
                    return nil
                }
            } else {
                // Unexpected character.
                return nil
            }
        }
        if (shiftedDistance != 24) {
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
        rawValue |= currentValue << 24
        value = rawValue
    }
    
    /// Returns an array of octets representing the parts of the IP address.
    public var octets: [UInt8] {
        return [UInt8(value & 0xFF),
                UInt8((value >> 8) & 0xFF),
                UInt8((value >> 16) & 0xFF),
                UInt8(value >> 24)]
    }
    
    /// Returns `true` if the IP address is an unspecified, if you listen on
    /// this address, your socket will listen on all addresses available.
    ///
    /// - Note: Equivalent to checking if the IP address is equal to
    ///         **0.0.0.0**.
    public var isUnspecified: Bool {
        return value == 0
    }
    
    /// Returns `true` if the IP address is a loopback address.
    ///
    /// - Note: Equivalent to checking if the IP address is in the subnet
    ///         **127.0.0.0/8**.
    public var isLoopback: Bool {
        return (value & 0x000000FF) == 0x0000007F
    }
    
    /// Returns `true` if the IP address is in one of the ranges reserved for
    /// private use. These addresses are not globally routable.
    ///
    /// - Note: The address ranges reserved for private use are as follows:
    ///     - **192.168.0.0/16** (65,536 IP addresses)
    ///     - **172.16.0.0/12** (1,048,576 IP addresses)
    ///     - **10.0.0.0/8** (16,777,216 IP addresses)
    public var isPrivate: Bool {
        return (value & 0x000000FF) == 0x0000000A ||
            (value & 0x0000F0FF) == 0x000010AC ||
            (value & 0x0000FFFF) == 0x0000A8C0
    }
    
    /// Returns `true` if the IP address is a link-local address.
    ///
    /// - Note: The address block reserved for link-local addresses is
    ///         **169.254.0.0/16**.
    public var isLinkLocal: Bool {
        return (value & 0x0000FFFF) == 0x0000FEA9
    }
    
    /// Returns `true` if the IP address is globally-routable.
    public var isGlobal: Bool {
        return !(
            // Unspecified Address
            value == 0x00000000 ||
            // Private Addresses
            (value & 0x000000FF) == 0x0000000A ||
            (value & 0x0000F0FF) == 0x000010AC ||
            (value & 0x0000FFFF) == 0x0000A8C0 ||
            // Loopback Address
            (value & 0x000000FF) == 0x0000007F ||
            // Link-Local Address
            (value & 0x0000FFFF) == 0x0000FEA9 ||
            // Broadcast Address
            value == 0xFFFFFFFF ||
            // Documentation Addresses
            (value & 0x00FFFFFF) == 0x000200C0 ||
            (value & 0x00FFFFFF) == 0x006433C6 ||
            (value & 0x00FFFFFF) == 0x007100CB
        )
    }
    
    /// Returns true if IP address is a multicast address.
    public var isMulticast: Bool {
        return value & 0x000000F0 == 0x000000E0
    }
    
    /// Returns true if the IP address is a broadcast address.
    public var isBroadcast: Bool {
        return value == 0xFFFFFFFF
    }
    
    /// Returns true if the IP address is in a block reserved for the purposes
    /// of having example IP addresses in written documentation.
    public var isDocumentation: Bool {
        return (value & 0x00FFFFFF) == 0x000200C0 ||
            (value & 0x00FFFFFF) == 0x006433C6 ||
            (value & 0x00FFFFFF) == 0x007100CB
    }
    
    /// Returns a string representation of the IP address.
    public var description: String {
        let o0 = Int(value & 0xFF)
        let o1 = Int((value >> 8) & 0xFF)
        let o2 = Int((value >> 16) & 0xFF)
        let o3 = Int(value >> 24)
        var out = firstQuad[o0]
        out.append(latterQuads[o1])
        out.append(latterQuads[o2])
        out.append(latterQuads[o3])
        return out
    }
    
    /// Returns an unspecified IP address.
    public static var any: IPv4Address {
        struct Static {
            static let anyAddress = IPv4Address.init()
        }
        return Static.anyAddress
    }
    
    /// Returns a representation of the IPv4 loopback address **127.0.0.1**.
    public static var loopback: IPv4Address {
        struct Static {
            static let loopbackAddress =
                IPv4Address.init(fromUInt32: 0x0100007F)
        }
        return Static.loopbackAddress
    }
    
    /// Returns a representation of the IPv4 broadcast address
    /// **255.255.255.255**.
    public static var broadcast: IPv4Address {
        struct Static {
            static let broadcastAddress =
                IPv4Address.init(fromUInt32: 0xFFFFFFFF)
        }
        return Static.broadcastAddress
    }
    
    /// Returns a Boolean value indicating whether IP addresses are equal.
    public static func == (lhs: IPv4Address, rhs: IPv4Address) -> Bool {
        return lhs.value == rhs.value
    }
}

/// Extracts an integer representation of the given IPv4 address in network-byte
/// order.
public extension UInt32 {
    init (fromIPv4Address ip: IPv4Address) {
        self = ip.value
    }
}
