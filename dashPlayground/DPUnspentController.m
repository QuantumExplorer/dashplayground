//
//  DPUnspentController.m
//  dashPlayground
//
//  Created by NATTAPON AIEMLAOR on 18/5/2561 BE.
//  Copyright © 2561 dashfoundation. All rights reserved.
//

#import "DPUnspentController.h"
#import "DPLocalNodeController.h"
#import "DialogAlert.h"

@implementation DPUnspentController

-(NSMutableArray*)processOutput:(NSDictionary*)unspentOutputs {
    
    NSMutableArray * unspentArray = [NSMutableArray array];
    
    for (NSDictionary* unspent in unspentOutputs) {
        
        NSDictionary * unspentTran = [self getTransactionInfo:[unspent valueForKey:@"txid"]];
        NSString *dateTime = [self getDateTime:[unspentTran valueForKey:@"time"]];
        
        NSDictionary * rDict = [NSMutableDictionary dictionary];
        
        [rDict setValue:[unspent valueForKey:@"account"] forKey:@"name"];
        [rDict setValue:[unspent valueForKey:@"txid"] forKey:@"txid"];
        [rDict setValue:[unspent valueForKey:@"confirmations"] forKey:@"confirmations"];
        [rDict setValue:[unspent valueForKey:@"amount"] forKey:@"amount"];
        [rDict setValue:[unspent valueForKey:@"address"] forKey:@"address"];
        [rDict setValue:dateTime forKey:@"time"];
        [unspentArray addObject:rDict];
    }
    
    return unspentArray;
}

-(void)retreiveUnspentOutput:(dashInfoClb)clb {
    
    __block NSDictionary * unspentArray = [NSDictionary dictionary];
    
    if (![[DPLocalNodeController sharedInstance] dashDPath]) {
        DialogAlert *dialog=[[DialogAlert alloc]init];
        NSAlert *findPathAlert = [dialog getFindPathAlert:@"dashd" exPath:@"~/Documents/src/dash/src"];
        
        if ([findPathAlert runModal] == NSAlertFirstButtonReturn) {
            //Find clicked
            NSString *pathString = [dialog getLaunchPath];
            [[DPLocalNodeController sharedInstance] setDashDPath:pathString];
            [[DialogAlert sharedInstance] showAlertWithOkButton:@"dashd" message:@"Set up dashd path successfully."];
        }
    }
    else{
        [[DPLocalNodeController sharedInstance] checkDash:^(BOOL active) {
            if (active) {
                unspentArray = [self getUnspentList];
                clb(YES,unspentArray,nil);
            } else {
                [[DPLocalNodeController sharedInstance] startDash:^(BOOL success, NSString *message) {
                    if (success) {
                        unspentArray = [self getUnspentList];
                        clb(YES,unspentArray,nil);
                    }
                    else{
                        [[DialogAlert sharedInstance] showWarningAlert:@"Error!" message:@"Unable to connect dashd server."];
                    }
                }];
            }
        }];
    }
}

-(NSString*)getDateTime:(NSString*)unixTimeStamp {
    NSTimeInterval _interval = [unixTimeStamp doubleValue];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:_interval];
    NSDateFormatter *formatter= [[NSDateFormatter alloc] init];
    [formatter setLocale:[NSLocale currentLocale]];
    [formatter setDateFormat:@"dd/MM/yy HH:mm"];
    NSString *dateString = [formatter stringFromDate:date];
    
    return dateString;
}

-(NSDictionary*)getUnspentList {
    NSDictionary* outputs = [[DPLocalNodeController sharedInstance] runDashRPCCommandArray:@"-testnet listunspent"];
    return outputs;
}

-(NSDictionary*)getTransactionInfo:(NSString*)txid {
    NSDictionary* outputs = [[DPLocalNodeController sharedInstance] runDashRPCCommandArray:[NSString stringWithFormat:@"-testnet gettransaction %@", txid]];
    return outputs;
}

-(void)createTransaction:(NSInteger)count label:(NSString*)label amount:(NSUInteger)amount allObjects:(NSArray*)allObjects clb:(dashArrayInfoClb)clb {
    //get local address
    NSMutableArray *addressArray = [[NSMutableArray alloc]init];
    for(int i = 1; i <= count; i++) {
        NSString *address = [[DPLocalNodeController sharedInstance] runDashRPCCommandString:@"-testnet getnewaddress \"\""];
        [addressArray addObject:[address stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]]];//remove /n];
    }
    
    //set label to address
    for(NSArray *address in addressArray) {
        NSString *labelCommand = [NSString stringWithFormat:@"-testnet setaccount %@ %@", address, label];
        [[DPLocalNodeController sharedInstance] runDashRPCCommandString:labelCommand];
    }
    
    NSMutableArray *inputsWithScriptPubKey = [NSMutableArray array];
    
    //get txid of unspent inputs first
    for(NSManagedObject *object in allObjects)
    {
        if([[object valueForKey:@"selected"] integerValue] != 1) continue;
        
        
        //get scriptPubKey
        NSString *validateCommand = [NSString stringWithFormat:@"-testnet getrawtransaction %@ 1", [object valueForKey:@"txid"]];
        NSDictionary *rawTransaction = [[DPLocalNodeController sharedInstance] runDashRPCCommandArray:validateCommand];
        NSDictionary *voutListDict = [rawTransaction objectForKey:@"vout"];
        NSDictionary *scriptPubKeyDict;
        NSUInteger vountIndex = 0;
        for(NSDictionary *voutElement in voutListDict)
        {
            if([[voutElement objectForKey:@"value"] integerValue] == [[object valueForKey:@"amount"] integerValue])
            {
                vountIndex = [[voutElement objectForKey:@"n"] integerValue];
                scriptPubKeyDict = [voutElement valueForKey:@"scriptPubKey"];
            }
        }
        
        NSDictionary *inputPubKeyDicts = [NSMutableDictionary dictionary];
        NSString *inputWithScriptPubKey = [NSString stringWithFormat:@"{\"txid\":\"%@\",\"vout\":%ld,\"scriptPubKey\":\"%@\"}"
                                           , [object valueForKey:@"txid"], vountIndex, [scriptPubKeyDict valueForKey:@"hex"]];
        
        [inputPubKeyDicts setValue:inputWithScriptPubKey forKey:@"input"];
        [inputsWithScriptPubKey addObject:inputPubKeyDicts];
    }
    
    if([inputsWithScriptPubKey count] == 0) {
        [[DialogAlert sharedInstance] showWarningAlert:@"Error" message:@"None of unspent output is selected."];
        return;
    }
    
    //append string for input with scriptPubKey
    NSUInteger countInputs = 1;
    NSMutableString *inputStringWithPubKey = [NSMutableString string];
    for(NSDictionary *input in inputsWithScriptPubKey)
    {
        [inputStringWithPubKey appendString:[input valueForKey:@"input"]];
        if(countInputs < [inputsWithScriptPubKey count]){
            [inputStringWithPubKey appendString:@","];
            countInputs = countInputs + 1;
        }
    }
    
    //let's create this shit
    NSString *processResult = [self processRawTransaction:amount toAddress:addressArray inputString:inputStringWithPubKey count:count];
    if(processResult != nil) {
        NSString *successStr = [NSString stringWithFormat:@"Create %d unspent outputs for %lu sucessfully. Please wait for a while the transaction is being processed...",(int)count , amount];
        [[DialogAlert sharedInstance] showAlertWithOkButton:@"Success" message:successStr];
        clb(YES,[self createTransactionToTable:addressArray]);
    }
    else {
        NSString *failedStr = [NSString stringWithFormat:@"Create unspent output failed."];
        [[DialogAlert sharedInstance] showWarningAlert:@"Error" message:failedStr];
        clb(NO,nil);
    }
}

-(NSString*)processRawTransaction:(NSUInteger)amount toAddress:(NSMutableArray*)address inputString:(NSMutableString*)inputStringWithPubKey
                            count:(NSInteger)count
{
    //create raw transaction
    //    createrawtransaction \”[{\”txid\":\"input-txid\",\"vout\”:1}]\” \”{\”destination-address\":amount}\”
    NSMutableString *destinationAddress = [NSMutableString string];
    for(NSInteger i = 1; i <= count; i++) {
        if(i == count) {
            [destinationAddress appendFormat:@"\"%@\":%ld", [address objectAtIndex:i-1], amount];
            break;
        }
        if(count > 1){
            [destinationAddress appendFormat:@"\"%@\":%ld,", [address objectAtIndex:i-1], amount];
        }
        else{
            [destinationAddress appendFormat:@"\"%@\":%ld,", [address objectAtIndex:i-1], amount];
        }
    }
//    NSString *addressParam = [NSString stringWithFormat:@"{\"%@\":%ld}", address, amount];
    NSString *addressParam = [NSString stringWithFormat:@"{%@}", destinationAddress];
    //    NSString *inputParam = [NSString stringWithFormat:@"[%@]", inputString];
    NSString *inputPubKeyParam = [NSString stringWithFormat:@"[%@]", inputStringWithPubKey];
    
    NSArray *createCommand = [NSArray arrayWithObjects:@"-testnet",@"createrawtransaction",inputPubKeyParam, addressParam, nil];
    NSString *createResult = [[DPLocalNodeController sharedInstance] runDashRPCCommandStringWithArray:createCommand];
    NSLog(@"Result: %@", createResult);
    if(createResult == nil) {
        return nil;
    }
    
    //fundrawtransaction
    //    fundrawtransaction 2323ofkofjifjewifjri2jr2ir... -> from create result
    createResult = [createResult stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];//remove /n
    NSArray *fundCommand = [NSArray arrayWithObjects:@"-testnet",@"fundrawtransaction",createResult, nil];
    NSDictionary *fundResult = [[DPLocalNodeController sharedInstance] runDashRPCCommandArrayWithArray:fundCommand];
    NSLog(@"Result: %@", fundResult);
    if(fundResult == nil) {
        return nil;
    }
    
    //signrawtransaction
    //    signrawtransaction 2323ofkofjifjewifjri2jr2ir... -> from fund output
    //    NSString *inputPubKeyParam = [NSString stringWithFormat:@"[%@]", inputStringWithPubKey];
    NSString *hexParam = [NSString stringWithFormat:@"%@", [fundResult valueForKey:@"hex"]];
    NSArray *signCommand = [NSArray arrayWithObjects:@"-testnet",@"signrawtransaction", hexParam, inputPubKeyParam, nil];
    NSDictionary *signResult = [[DPLocalNodeController sharedInstance] runDashRPCCommandArrayWithArray:signCommand];
    NSLog(@"Result: %@", signResult);
    if(signResult == nil) {
        return nil;
    }
    else if([signResult valueForKey:@"errors"])
    {
        NSDictionary *signError = [signResult valueForKey:@"errors"];
        [[DialogAlert sharedInstance] showAlertWithOkButton:@"Error" message:[signError valueForKey:@"error"]];
        return nil;
    }
    
    //sendrawtransaction
    //    sendrawtransaction 2323ofkofjifjewifjri2jr2ir... -> from sign output
    NSArray *sendCommand = [NSArray arrayWithObjects:@"-testnet",@"sendrawtransaction",[signResult valueForKey:@"hex"], nil];
    NSString *sendResult = [[DPLocalNodeController sharedInstance] runDashRPCCommandStringWithArray:sendCommand];
    NSLog(@"Result: %@", sendResult);
    return sendResult;
}

-(NSMutableArray*)createTransactionToTable:(NSMutableArray*)addressArray {
    
    NSMutableArray *newData = [NSMutableArray array];
    
    for(NSArray *address in addressArray) {
        NSDictionary *tranDicts = [NSMutableDictionary dictionary];
        [tranDicts setValue:@"processing" forKey:@"name"];
        [tranDicts setValue:@"processing" forKey:@"time"];
        [tranDicts setValue:@"processing" forKey:@"txid"];
        [tranDicts setValue:@"processing" forKey:@"amount"];
        [tranDicts setValue:@"processing" forKey:@"confirmations"];
        [tranDicts setValue:address forKey:@"address"];
        [newData addObject:tranDicts];
    }
    
    return newData;
}

#pragma mark - Singleton methods

+ (DPUnspentController *)sharedInstance
{
    static DPUnspentController *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[DPUnspentController alloc] init];
        
        // Do any other initialisation stuff here
    });
    return sharedInstance;
}

@end
