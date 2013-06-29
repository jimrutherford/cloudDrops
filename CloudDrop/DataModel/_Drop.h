// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Drop.h instead.

#import <CoreData/CoreData.h>


extern const struct DropAttributes {
	__unsafe_unretained NSString *clipboardURL;
	__unsafe_unretained NSString *dropDestinationService;
	__unsafe_unretained NSString *filename;
	__unsafe_unretained NSString *iconImageName;
	__unsafe_unretained NSString *timestamp;
} DropAttributes;

extern const struct DropRelationships {
} DropRelationships;

extern const struct DropFetchedProperties {
} DropFetchedProperties;








@interface DropID : NSManagedObjectID {}
@end

@interface _Drop : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (DropID*)objectID;




@property (nonatomic, strong) NSString* clipboardURL;


//- (BOOL)validateClipboardURL:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* dropDestinationService;


//- (BOOL)validateDropDestinationService:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* filename;


//- (BOOL)validateFilename:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSString* iconImageName;


//- (BOOL)validateIconImageName:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSNumber* timestamp;


@property int64_t timestampValue;
- (int64_t)timestampValue;
- (void)setTimestampValue:(int64_t)value_;

//- (BOOL)validateTimestamp:(id*)value_ error:(NSError**)error_;






@end

@interface _Drop (CoreDataGeneratedAccessors)

@end

@interface _Drop (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveClipboardURL;
- (void)setPrimitiveClipboardURL:(NSString*)value;




- (NSString*)primitiveDropDestinationService;
- (void)setPrimitiveDropDestinationService:(NSString*)value;




- (NSString*)primitiveFilename;
- (void)setPrimitiveFilename:(NSString*)value;




- (NSString*)primitiveIconImageName;
- (void)setPrimitiveIconImageName:(NSString*)value;




- (NSNumber*)primitiveTimestamp;
- (void)setPrimitiveTimestamp:(NSNumber*)value;

- (int64_t)primitiveTimestampValue;
- (void)setPrimitiveTimestampValue:(int64_t)value_;




@end
