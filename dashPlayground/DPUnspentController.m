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
#import "DPDataStore.h"

@implementation DPUnspentController

-(void)processOutput:(NSDictionary*)unspentOutputs forChain:(NSString*)chainNetwork clb:(dashDictInfoClb)clb {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{

        for (NSDictionary* unspent in unspentOutputs) {

//            NSDictionary * unspentTran = [self getTransactionInfo:[unspent valueForKey:@"txid"] forChain:chainNetwork];
//            NSString *dateTime = [self getDateTime:[unspentTran valueForKey:@"time"]];

            NSDictionary * rDict = [NSMutableDictionary dictionary];

            [rDict setValue:[unspent valueForKey:@"account"] forKey:@"name"];
            [rDict setValue:[unspent valueForKey:@"txid"] forKey:@"txid"];
            [rDict setValue:[unspent valueForKey:@"confirmations"] forKey:@"confirmations"];
            [rDict setValue:[unspent valueForKey:@"amount"] forKey:@"amount"];
            [rDict setValue:[unspent valueForKey:@"address"] forKey:@"address"];
//            [rDict setValue:dateTime forKey:@"time"];
        }

    });
    
}

-(void)retreiveUnspentOutput:(dashInfoClb)clb forChain:(NSString*)chainNetwork {
    
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
                unspentArray = [self getUnspentList:chainNetwork];
                clb(YES,unspentArray,nil);
            } else {
                [[DPLocalNodeController sharedInstance] startDash:^(BOOL success, NSString *message) {
                    if (success) {
                        unspentArray = [self getUnspentList:chainNetwork];
                        clb(YES,unspentArray,nil);
                    }
                    else{
                        [[DialogAlert sharedInstance] showWarningAlert:@"Error!" message:@"Unable to connect dashd server."];
                        clb(NO,nil,nil);
                    }
                } forChain:chainNetwork];
            }
        } forChain:chainNetwork];
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

-(NSDictionary*)getUnspentList:(NSString*)chainNetwork {
    NSString *command = [NSString stringWithFormat:@"-%@ listunspent", chainNetwork];
    if ([chainNetwork rangeOfString:@"devnet"].location != NSNotFound) {
        command = [NSString stringWithFormat:@"-%@ -rpcport=12998 -port=12999 listunspent", chainNetwork];
    }
    __block NSDictionary *outputs;
    [[DPLocalNodeController sharedInstance] runDashRPCCommandArray:command checkError:NO onClb:^(BOOL success, NSDictionary *object) {
        outputs = object;
    }];
    return outputs;
}

-(NSDictionary*)getTransactionInfo:(NSString*)txid forChain:(NSString*)chainNetwork {
    NSString *command = [NSString stringWithFormat:@"-%@ gettransaction %@", chainNetwork, txid];
    if ([chainNetwork rangeOfString:@"devnet"].location != NSNotFound) {
        command = [NSString stringWithFormat:@"-%@ -rpcport=12998 -port=12999 gettransaction %@", chainNetwork, txid];
    }
    
    __block NSDictionary* outputs;
    [[DPLocalNodeController sharedInstance] runDashRPCCommandArray:command checkError:YES onClb:^(BOOL success, NSDictionary *object) {
        outputs = object;
    }];
    return outputs;
}

-(void)createTransaction:(NSInteger)count label:(NSString*)label amount:(NSUInteger)amount allObjects:(NSArray*)allObjects clb:(dashMutaArrayInfoClb)clb forChain:(NSString*)chainNetwork {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        //get local address
        NSMutableArray *addressArray = [[NSMutableArray alloc]init];
        for(int i = 1; i <= count; i++) {
            NSString *address = [[DPLocalNodeController sharedInstance] runDashRPCCommandString:@"getnewaddress \"\"" forChain:chainNetwork];
            [addressArray addObject:[address stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]]];//remove /n];
        }
        
        //set label to address
        for(NSArray *address in addressArray) {
            NSString *labelCommand = [NSString stringWithFormat:@"setaccount %@ %@", address, label];
            [[DPLocalNodeController sharedInstance] runDashRPCCommandString:labelCommand forChain:chainNetwork];
        }
        
        NSMutableArray *inputsWithScriptPubKey = [NSMutableArray array];
        
        //get txid of unspent inputs first
        for(NSManagedObject *object in allObjects)
        {
            if([[object valueForKey:@"selected"] integerValue] != 1) continue;
            
            
            //get scriptPubKey
            NSString *validateCommand = [NSString stringWithFormat:@"-%@ getrawtransaction %@ 1", chainNetwork, [object valueForKey:@"txid"]];
            if ([chainNetwork rangeOfString:@"devnet"].location != NSNotFound) {
                validateCommand = [NSString stringWithFormat:@"-%@ -rpcport=12998 -port=12999 getrawtransaction %@ 1", chainNetwork, [object valueForKey:@"txid"]];
            }
            __block NSDictionary *rawTransaction;
            [[DPLocalNodeController sharedInstance] runDashRPCCommandArray:validateCommand checkError:YES onClb:^(BOOL success, NSDictionary *object) {
                if(object != nil) rawTransaction = object;
            }];
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
            dispatch_async(dispatch_get_main_queue(), ^{
                [[DialogAlert sharedInstance] showWarningAlert:@"Error" message:@"None of unspent output is selected."];
            });
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
        NSString *processResult = [self processRawTransaction:amount toAddress:addressArray inputString:inputStringWithPubKey count:count forChain:chainNetwork];
        
        NSString *successStr = [NSString stringWithFormat:@"Create %d unspent outputs for %lu result %@",(int)count , amount, processResult];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[DialogAlert sharedInstance] showAlertWithOkButton:@"Result" message:successStr];
        });
        
//        if(processResult != nil) {
//            NSString *successStr = [NSString stringWithFormat:@"Create %d unspent outputs for %lu sucessfully. Please wait for a while the transaction is being processed...",(int)count , amount];
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [[DialogAlert sharedInstance] showAlertWithOkButton:@"Success" message:successStr];
//            });
//            clb(YES,[self createTransactionToTable:addressArray]);
//        }
//        else {
//            NSString *failedStr = [NSString stringWithFormat:@"Create unspent output failed."];
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [[DialogAlert sharedInstance] showWarningAlert:@"Error" message:failedStr];
//            });
//            clb(NO,nil);
//        }
    });
}

-(NSString*)processRawTransaction:(NSUInteger)amount toAddress:(NSMutableArray*)address inputString:(NSMutableString*)inputStringWithPubKey
                            count:(NSInteger)count forChain:(NSString*)chainNetwork
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
    
    NSString *chainNet = [NSString stringWithFormat:@"-%@", chainNetwork];
    NSArray *createCommand = [NSArray arrayWithObjects:chainNet,@"createrawtransaction",inputPubKeyParam, addressParam, nil];
    if ([chainNetwork rangeOfString:@"devnet"].location != NSNotFound) {
        createCommand = [NSArray arrayWithObjects:chainNet,@"-rpcport=12998",@"-port=12999",@"createrawtransaction",inputPubKeyParam, addressParam, nil];
    }
    
    NSString *createResult = [[DPLocalNodeController sharedInstance] runDashRPCCommandStringWithArray:createCommand];
    NSLog(@"Result: %@", createResult);
    if(createResult == nil) {
        return nil;
    }
    
    //fundrawtransaction
    //    fundrawtransaction 2323ofkofjifjewifjri2jr2ir... -> from create result
    createResult = [createResult stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];//remove /n
    NSArray *fundCommand = [NSArray arrayWithObjects:chainNet,@"fundrawtransaction",createResult, nil];
    if ([chainNetwork rangeOfString:@"devnet"].location != NSNotFound) {
        fundCommand = [NSArray arrayWithObjects:chainNet,@"-rpcport=12998",@"-port=12999",@"fundrawtransaction",createResult, nil];
    }
    NSDictionary *fundResult = [[DPLocalNodeController sharedInstance] runDashRPCCommandArrayWithArray:fundCommand];
    NSLog(@"Result: %@", fundResult);
    if(fundResult == nil) {
        return nil;
    }
    
    //signrawtransaction
    //    signrawtransaction 2323ofkofjifjewifjri2jr2ir... -> from fund output
    //    NSString *inputPubKeyParam = [NSString stringWithFormat:@"[%@]", inputStringWithPubKey];
    NSString *hexParam = [NSString stringWithFormat:@"%@", [fundResult valueForKey:@"hex"]];
    NSArray *signCommand = [NSArray arrayWithObjects:chainNet,@"signrawtransaction", hexParam, inputPubKeyParam, nil];
    if ([chainNetwork rangeOfString:@"devnet"].location != NSNotFound) {
        signCommand = [NSArray arrayWithObjects:chainNet,@"-rpcport=12998",@"-port=12999",@"signrawtransaction", hexParam, inputPubKeyParam, nil];
    }
    NSDictionary *signResult = [[DPLocalNodeController sharedInstance] runDashRPCCommandArrayWithArray:signCommand];
    NSLog(@"Result: %@", signResult);
    if(signResult == nil) {
        return nil;
    }
    else if([signResult valueForKey:@"errors"])
    {
        NSDictionary *signError = [signResult valueForKey:@"errors"];
        NSLog(@"%@", [signError valueForKey:@"error"]);
        dispatch_async(dispatch_get_main_queue(), ^{
            [[DialogAlert sharedInstance] showAlertWithOkButton:@"Error" message:[signError valueForKey:@"error"]];
        });
        return nil;
    }
    
    //sendrawtransaction
    //    sendrawtransaction 2323ofkofjifjewifjri2jr2ir... -> from sign output
    NSArray *sendCommand = [NSArray arrayWithObjects:chainNet,@"sendrawtransaction",[signResult valueForKey:@"hex"], nil];
    if ([chainNetwork rangeOfString:@"devnet"].location != NSNotFound) {
        sendCommand = [NSArray arrayWithObjects:chainNet,@"-rpcport=12998",@"-port=12999",@"sendrawtransaction",[signResult valueForKey:@"hex"], nil];
    }
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
