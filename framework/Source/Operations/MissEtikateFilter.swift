/** A photo filter based on Photoshop action by Miss Etikate:
 http://miss-etikate.deviantart.com/art/Photoshop-Action-15-120151961
 */

// Note: If you want to use this effect you have to add lookup_miss_etikate.png
//       from Resources folder to your application bundle.

#if !os(Linux)
public class MissEtikateFilter: LookupFilter {
    public override init() {
        super.init()
        
        do {
            try ({lookupImage = try PictureInput(imageName:"lookup_miss_etikate.png")})()
        }
        catch {
            print("ERROR: Unable to create PictureInput \(error)")
        }
    }
}
#endif
