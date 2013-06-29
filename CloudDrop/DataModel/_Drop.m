// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Drop.m instead.

#import "_Drop.h"

const struct DropAttributes DropAttributes = {
	.clipboardURL = @"clipboardURL",
	.dropDestinationService = @"dropDestinationService",
	.filename = @"filename",
	.iconImageName = @"iconImageName",
	.timestamp = @"timestamp",
};

const struct DropRelationships DropRelationships = {
};

const struct DropFetchedProperties DropFetchedProperties = {
};

@implementation DropID
@end

@implementation _Drop

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Drop" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Drop";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Drop" inManagedObjectContext:moc_];
}

- (DropID*)objectID {
	return (DropID*)[super objectID];
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"timestampValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"timestamp"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}

	return keyPaths;
}




@dynamic clipboardURL;






@dynamic dropDestinationService;






@dynamic filename;






@dynamic iconImageName;






@dynamic timestamp;



- (int64_t)timestampValue {
	NSNumber *result = [self timestamp];
	return [result longLongValue];
}

- (void)setTimestampValue:(int64_t)value_ {
	[self setTimestamp:[NSNumber numberWithLongLong:value_]];
}

- (int64_t)primitiveTimestampValue {
	NSNumber *result = [self primitiveTimestamp];
	return [result longLongValue];
}

- (void)setPrimitiveTimestampValue:(int64_t)value_ {
	[self setPrimitiveTimestamp:[NSNumber numberWithLongLong:value_]];
}










@end
