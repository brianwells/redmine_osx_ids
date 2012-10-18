require 'inline'

class Inline::ObjC < Inline::C
  def initialize(mod)
    super(mod)
  end

  def import(header)
    @src << "#import #{header}"
  end
end

class OpenDirectory

  def self.nodes
    nodeNames
  end

  def self.userGUID(name, node = "/Search")
    recordGUID(name, "dsRecTypeStandard:Users", node)
  end

  def self.groupGUID(name, node = "/Search")
    recordGUID(name, "dsRecTypeStandard:Groups", node)
  end

  def self.recordName(name, node = "/Search")
    name4record(name, node)
  end

  def self.authenticatedUser(name, password, node = "/Search")
    userauth(name,password,node)
  end

  def self.userAttributes(name, attrs, node = "/Search")
    attributes4user(name, attrs, node)
  end
    
  def self.groupContainsUser(group, user, node = "/Search")
    memberOfGroup(user, group, node)
  end

  def self.usersInGroupByName(group, node = "/Search")
    usersInGroup(group, "dsAttrTypeStandard:RecordName", node)
  end

  def self.usersInGroupByGUID(group, node = "/Search")
    usersInGroup(group, "dsAttrTypeStandard:GeneratedUID", node)
  end

  def self.nodeDetails(node = "/Search")
    details4node(node)
  end



  inline(:ObjC) do |builder|
    builder.import "<CoreFoundation/CoreFoundation.h>"
    builder.import "<OpenDirectory/OpenDirectory.h>"
    builder.add_compile_flags '-x objective-c'
    builder.add_compile_flags '-framework Foundation', '-framework OpenDirectory'

    builder.prefix %q{

ODRecord * findrecord(NSString *name, ODAttributeType type, id attrs, ODNode *node, NSError **err) {
    NSArray *records = nil;
    // find record by GUID
    ODQuery *query = [ODQuery queryWithNode:node
                             forRecordTypes:type
                                  attribute:kODAttributeTypeGUID
                                  matchType:kODMatchEqualTo
                                queryValues:name
                           returnAttributes:attrs
                             maximumResults:0
                                      error:err];
    if (!*err) {
        records = [query resultsAllowingPartial:NO error:err];
    }
    if (*err || !records || [records count] == 0) {
        // find record by distinguished name
        ODQuery *group_query = [ODQuery queryWithNode:node
                                       forRecordTypes:type
                                            attribute:@"dsAttrTypeNative:distinguishedName"
                                            matchType:kODMatchEqualTo
                                          queryValues:name
                                     returnAttributes:attrs
                                       maximumResults:0
                                                error:err];
        if (!*err) {
            records = [group_query resultsAllowingPartial:NO error:err];
        }
    }
    if (*err || !records || [records count] == 0) {
        // find record by record name
        ODQuery *query = [ODQuery queryWithNode:node
                                 forRecordTypes:type
                                      attribute:kODAttributeTypeRecordName
                                      matchType:kODMatchInsensitiveEqualTo
                                    queryValues:name
                               returnAttributes:attrs
                                 maximumResults:0
                                          error:err];
        if (!*err) {
            records = [query resultsAllowingPartial:NO error:err];
        }
    }
    if (!*err && records && [records count] > 0) {
        return [records objectAtIndex:0];
    } else {
        return nil;
    }
}
 
NSSet * users4group(ODRecord *group, ODNode *node, ODAttributeType type, NSError **err) {
    NSMutableSet *users = [NSMutableSet setWithCapacity:5];
    // get list of members using AD method
    NSArray *members = [group valuesForAttribute:@"dsAttrTypeNative:member" error:err];
    if (*err || !members || [members count] == 0) {
        // try standard list of membership
        members = [group valuesForAttribute:kODAttributeTypeGroupMembership error:err];
    }
    if (!*err && members) {
        for (NSString *membername in members) {
            ODRecord *user = findrecord(membername, kODRecordTypeUsers, type, node, err);
            if (!*err && user) {
                // got user... fetch type
                NSArray *values = [user valuesForAttribute:type error:err];
                if (!*err && values && [values count] > 0) {
                    [users addObject:[values objectAtIndex:0]];
                }
            } else {
                ODRecord *group = findrecord(membername, kODRecordTypeGroups, [NSArray arrayWithObjects:@"dsAttrTypeNative:member", kODAttributeTypeGroupMembership, nil], node, err);
                if (!*err && group) {
                    // got group...
                    [users unionSet:users4group(group,node,type,err)];
                }
            }
            if (*err) {
                break;
            }
        }
    }
    return users;
}

VALUE arrayForValues(NSArray *values) {
    char base64_table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    VALUE value_array = Qnil;
    if (values && [values count] > 0) {
        value_array = rb_ary_new2([values count]);
        for (NSObject *v in values) {
            if ([v isKindOfClass:[NSData class]]) {
            // convert data to base64 string
            size_t size = [(NSData *)v length];
            const unsigned char *input = [(NSData *)v bytes];
            unsigned char *output = malloc(size * 4 / 3 + 4);
            uint32_t x = 0;
            uint32_t y = 0;
            uint64_t z = 0;
            while (x < size) {
                z  = (x < size ? input[x] : 0) * 65536;
                x++;
                z += (x < size ? input[x] : 0) * 256;
                x++;
                z += (x < size ? input[x] : 0);
                x++;
                output[y++] = base64_table[(z >> 18) & 0x3F];
                output[y++] = base64_table[(z >> 12) & 0x3F];
                output[y++] = base64_table[(z >>  6) & 0x3F];
                output[y++] = base64_table[z & 0x3F];
                if (x > size)
                    output[y - 1] = '=';
                if (x > size + 1)
                    output[y - 2] = '=';
                }
                output[y] = 0;
                v = [NSString stringWithUTF8String:output];
            }
            if (![v isKindOfClass:[NSString class]]) {
                v = [v description];
            }
            rb_ary_push(value_array, rb_str_new2([(NSString *)v UTF8String]));
        }
    }
    return value_array;
}

    }
    
    builder.c_singleton %q{

VALUE nodeNames() {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    VALUE array = Qnil;
    ODSession *session = [ODSession defaultSession];
    NSArray *names = [session nodeNamesAndReturnError:nil];
    if (names) {
        array = rb_ary_new2([names count]);
        for (NSString *name in names) {
            rb_ary_push(array, rb_str_new2([name UTF8String]));
        }
    }
    [pool drain];
    return array;
}
    }

    builder.c_singleton %q{

VALUE recordGUID(char *name, char *type, char *node_name) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    VALUE result = Qnil;
    NSError *err = nil;
    ODSession *session = [ODSession defaultSession];
    ODNode *node = [ODNode nodeWithSession:session name:[NSString stringWithUTF8String:node_name] error:&err];
    if (!err && node) {
        // find record
        ODRecord *record = findrecord([NSString stringWithUTF8String:name], [NSString stringWithUTF8String:type], kODAttributeTypeGUID, node, &err);
        if (!err && record) {
            // get GUID attribute
            NSArray *values = [record valuesForAttribute:kODAttributeTypeGUID error:&err];
            if (!err && values && [values count] > 0) {
                result = rb_str_new2([[values objectAtIndex:0] UTF8String]);
            }
        }
    }
    [pool drain];
    return result;
}
    }

    builder.c_singleton %q{

VALUE name4record(char *guid, char *node_name) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    VALUE result = Qnil;
    NSError *err = nil;
    ODSession *session = [ODSession defaultSession];
    ODNode *node = [ODNode nodeWithSession:session name:[NSString stringWithUTF8String:node_name] error:&err];
    if (!err && node) {
        ODRecord *record = findrecord([NSString stringWithUTF8String:guid], [NSArray arrayWithObjects:@"dsRecTypeStandard:Users",@"dsRecTypeStandard:Groups",nil], kODAttributeTypeRecordName, node, &err);
        if (!err && record) {
            NSArray *values = [record valuesForAttribute:kODAttributeTypeRecordName error:&err];
            if (!err && values && [values count] > 0) {
                result = rb_str_new2([[values objectAtIndex:0] UTF8String]);
            }
        }
    }
    [pool drain];
    return result;
}
    }

    builder.c_singleton %q{

VALUE userauth(char *name, char *password, char *node_name) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    VALUE result = Qfalse;
    NSError *err = nil;
    ODRecord *user = nil;
    ODSession *session = [ODSession defaultSession];
    ODNode *node = [ODNode nodeWithSession:session name:[NSString stringWithUTF8String:node_name] error:&err];
    if (!err && node) {
        user = findrecord([NSString stringWithUTF8String:name], kODRecordTypeUsers, nil, node, &err);
    }
    if (!err && user) {
        // authenticate user
        if ([user verifyPassword:[NSString stringWithUTF8String:password] error:nil]) {
            result = Qtrue;
        }
    }
    [pool drain];
    return result;
}

    }

    builder.c_singleton %q{

VALUE attributes4user(char *name, VALUE attrs, char *node_name) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    VALUE results = Qnil;
    NSError *err = nil;
    ODRecord *user = nil;
    ODSession *session = [ODSession defaultSession];
    ODNode *node = [ODNode nodeWithSession:session name:[NSString stringWithUTF8String:node_name] error:&err];
    long attrs_len = RARRAY_LEN(attrs);
    VALUE *attrs_arr = RARRAY_PTR(attrs);
    NSMutableArray *attributes = [NSMutableArray arrayWithCapacity:attrs_len];
    int i;

    for (i = 0; i < attrs_len; i++) {
        [attributes addObject: [NSString stringWithUTF8String:StringValuePtr(attrs_arr[i])]];
    }

    if (!err && node) {
        user = findrecord([NSString stringWithUTF8String:name], kODRecordTypeUsers, attributes, node, &err);
        if (!err && user) {
            // get attributes
            results = rb_hash_new();
            for (NSString *attr in attributes) {
                NSArray *values = [user valuesForAttribute:attr error:&err];
                if (!err) {
                    VALUE value_array = arrayForValues(values);
                    if (value_array != Qnil) {
                        rb_hash_aset(results, rb_str_new2([attr UTF8String]), value_array);
                    }
                }
            }
        }
    }
    [pool drain];
    return results;
}

    }

    builder.c_singleton %q{

VALUE memberOfGroup(char *user_name, char *group_name, char *node_name) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    VALUE result = Qfalse;
    NSError *err = nil;
    ODRecord *group = nil;
    ODRecord *user = nil;
    ODSession *session = [ODSession defaultSession];
    ODNode *node = [ODNode nodeWithSession:session name:[NSString stringWithUTF8String:node_name] error:&err];
    if (!err && node) {
        group = findrecord([NSString stringWithUTF8String:group_name], kODRecordTypeGroups, nil, node, &err);
        user = findrecord([NSString stringWithUTF8String:user_name], kODRecordTypeUsers, nil, node, &err);
        if (!err && user && group && [group isMemberRecord:user error:nil]) {
            result = Qtrue;
        }
    }
    [pool drain];
    return result;
}

    }

    builder.c_singleton %q{

VALUE usersInGroup(char *group_name, char *type_name, char *node_name) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    VALUE array = Qnil;
    NSError *err = nil;
    ODRecord *group = nil;
    ODSession *session = [ODSession defaultSession];
    ODNode *node = [ODNode nodeWithSession:session name:[NSString stringWithUTF8String:node_name] error:&err];
    if (!err && node) {
        // find initial group
        group = findrecord([NSString stringWithUTF8String:group_name], kODRecordTypeGroups, nil, node, &err);
    }
    if (!err && group) {
        NSSet *names = users4group(group, node, [NSString stringWithUTF8String:type_name], &err);
        array = rb_ary_new2([names count]);
        for (NSString *name in names) {
            rb_ary_push(array, rb_str_new2([name UTF8String]));
        }
    }
    [pool drain];
    return array;
}

    }
    
    builder.c_singleton %q{
   
VALUE details4node(char *name) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    VALUE results = Qnil;
    NSError *err = nil;
    NSDictionary *details = nil;
    char base64_table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    ODSession *session = [ODSession defaultSession];
    ODNode *node = [ODNode nodeWithSession:session name:[NSString stringWithUTF8String:name] error:&err];
    if (!err && node) {
        details = [node nodeDetailsForKeys:nil error:&err];
    }
    if (!err && details) {
            results = rb_hash_new();
            for (NSString *attr in details) {
                VALUE value_array = arrayForValues([details objectForKey:attr]);
                if (value_array != Qnil) {
                    rb_hash_aset(results, rb_str_new2([attr UTF8String]), value_array);
                }
            }
    }
    [pool drain];
    return results;
}

    }
    
  end
end
