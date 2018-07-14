//
//  DebugTypeTransformer.m
//  dashPlayground
//
//  Created by NATTAPON AIEMLAOR on 27/6/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//

#import "DebugTypeTransformer.h"

@implementation DebugTypeTransformer

+ (Class)transformedValueClass
{
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValueByInteger:(id)value
{
    switch ([value integerValue]) {
        case DPMessageOriginatorClass_CreateNewBlock:
            return @"CreateNewBlock";
            break;
        case DPMessageOriginatorClass_ConnectBlock:
            return @"ConnectBlock";
            break;
        case DPMessageOriginatorClass_DisconnectBlocks:
            return @"DisconnectBlocks";
            break;
        case DPMessageOriginatorClass_CMasternodePayments:
            return @"CMasternodePayments";
            break;
        case DPMessageOriginatorClass_MASTERNODEPAYMENTSYNC:
            return @"MASTERNODEPAYMENTSYNC";
            break;
        case DPMessageOriginatorClass_MASTERNODEPAYMENTVOTE:
            return @"MASTERNODEPAYMENTVOTE";
            break;
        case DPMessageOriginatorClass_CMasternodePaymentVote:
            return @"CMasternodePaymentVote";
            break;
        case DPMessageOriginatorClass_CMasternodeBlockPayees:
            return @"CMasternodeBlockPayees";
            break;
        case DPMessageOriginatorClass_CMasternodeMan:
            return @"CMasternodeMan";
            break;
        case DPMessageOriginatorClass_CMasternode:
            return @"CMasternode";
            break;
        case DPMessageOriginatorClass_MasternodeMan:
            return @"MasternodeMan";
            break;
        case DPMessageOriginatorClass_CGovernanceVoting:
            return @"CGovernanceVoting";
            break;
        case DPMessageOriginatorClass_CGovernanceVote:
            return @"CGovernanceVote";
            break;
        case DPMessageOriginatorClass_MNGOVERNANCEOBJECT:
            return @"MNGOVERNANCEOBJECT";
            break;
        case DPMessageOriginatorClass_CGovernanceManager:
            return @"CGovernanceManager";
            break;
        case DPMessageOriginatorClass_DSACCEPT:
            return @"DSACCEPT";
            break;
        case DPMessageOriginatorClass_DSVIN:
            return @"DSVIN";
            break;
        case DPMessageOriginatorClass_CPrivateSendServer:
            return @"CPrivateSendServer";
            break;
        case DPMessageOriginatorClass_DSTX:
            return @"DSTX";
            break;
        case DPMessageOriginatorClass_TXLOCKREQUEST:
            return @"TXLOCKREQUEST";
            break;
        case DPMessageOriginatorClass_CTxMemPool:
            return @"CTxMemPool";
            break;
        case DPMessageOriginatorClass_CDarksendQueue:
            return @"CDarksendQueue";
            break;
        case DPMessageOriginatorClass_CDarksendBroadcastTx:
            return @"CDarksendBroadcastTx";
            break;
        case DPMessageOriginatorClass_CPrivateSend:
            return @"CPrivateSend";
            break;
        case DPMessageOriginatorClass_DSQUEUE:
            return @"DSQUEUE";
            break;
        case DPMessageOriginatorClass_DSSTATUSUPDATE:
            return @"DSSTATUSUPDATE";
            break;
        case DPMessageOriginatorClass_DSFINALTX:
            return @"DSFINALTX";
            break;
        case DPMessageOriginatorClass_CPrivateSendClient:
            return @"CPrivateSendClient";
            break;
        case DPMessageOriginatorClass_CompletedTransaction:
            return @"CompletedTransaction";
            break;
        case DPMessageOriginatorClass_AcceptConnection:
            return @"AcceptConnection";
            break;
        case DPMessageOriginatorClass_ThreadSocketHandler:
            return @"ThreadSocketHandler";
            break;
        case DPMessageOriginatorClass_CNode:
            return @"CNode";
            break;
        case DPMessageOriginatorClass_CGovernanceTriggerManager:
            return @"CGovernanceTriggerManager";
            break;
        case DPMessageOriginatorClass_CSuperblockManager:
            return @"CSuperblockManager";
            break;
        case DPMessageOriginatorClass_CSuperblock:
            return @"CSuperblock";
            break;
        case DPMessageOriginatorClass_CMasternodeSync:
            return @"CMasternodeSync";
            break;
        case DPMessageOriginatorClass_SYNCSTATUSCOUNT:
            return @"SYNCSTATUSCOUNT";
            break;
        case DPMessageOriginatorClass_CActiveDeterministicMasternodeManager:
            return @"CActiveDeterministicMasternodeManager";
            break;
        case DPMessageOriginatorClass_CActiveLegacyMasternodeManager:
            return @"CActiveLegacyMasternodeManager";
            break;
        case DPMessageOriginatorClass_CActiveMasternode:
            return @"CActiveMasternode";
            break;
        case DPMessageOriginatorClass_CKeyHolderStorage:
            return @"CKeyHolderStorage";
            break;
        case DPMessageOriginatorClass_CGovernanceObject:
            return @"CGovernanceObject";
            break;
        case DPMessageOriginatorClass_CGovernance:
            return @"CGovernance";
            break;
        case DPMessageOriginatorClass_CInstantSend:
            return @"CInstantSend";
            break;
        case DPMessageOriginatorClass_CTxLockVote:
            return @"CTxLockVote";
            break;
        case DPMessageOriginatorClass_CSporkManager:
            return @"CSporkManager";
            break;
        case DPMessageOriginatorClass_CSporkMessage:
            return @"CSporkMessage";
            break;
        case DPMessageOriginatorClass_CMasternodeBroadcast:
            return @"CMasternodeBroadcast";
            break;
        case DPMessageOriginatorClass_CMasternodePing:
            return @"CMasternodePing";
            break;
        case DPMessageOriginatorClass_CMessageHeader:
            return @"CMessageHeader";
            break;
        default:
            return @"Unknown";
            break;
    }
}

- (NSMutableArray*)getAllDataTypes {
    NSMutableArray *dataTypes = [@[@"All", @"CreateNewBlock", @"ConnectBlock", @"DisconnectBlocks"
                                   , @"CMasternodePayments", @"MASTERNODEPAYMENTSYNC", @"MASTERNODEPAYMENTVOTE"
                                   , @"CMasternodePaymentVote", @"CMasternodeBlockPayees", @"CMasternodeMan"
                                   , @"CMasternode", @"MasternodeMan", @"CGovernanceVoting"
                                   , @"CGovernanceVote", @"MNGOVERNANCEOBJECT", @"CGovernanceManager"
                                   , @"DSACCEPT", @"DSVIN", @"CPrivateSendServer"
                                   , @"DSTX", @"TXLOCKREQUEST", @"CTxMemPool"
                                   , @"CDarksendQueue", @"CDarksendBroadcastTx", @"CPrivateSend"
                                   , @"DSQUEUE", @"DSSTATUSUPDATE", @"DSFINALTX"
                                   , @"CPrivateSendClient", @"CompletedTransaction", @"AcceptConnection"
                                   , @"ThreadSocketHandler", @"CNode", @"CGovernanceTriggerManager"
                                   , @"CSuperblockManager", @"CSuperblock", @"CMasternodeSync"
                                   , @"SYNCSTATUSCOUNT", @"CActiveDeterministicMasternodeManager", @"CActiveLegacyMasternodeManager"
                                   , @"CActiveMasternode", @"CKeyHolderStorage", @"CGovernanceObject"
                                   , @"CGovernance", @"CInstantSend", @"CTxLockVote"
                                   , @"CSporkManager", @"CSporkMessage", @"CMasternodeBroadcast"
                                   , @"CMasternodePing", @"CMessageHeader"] mutableCopy];
    
    return dataTypes;
}

- (int)getDataTypeByString:(NSString*)string {
    
    NSMutableArray *dataTypes = [self getAllDataTypes];
    for(int i = 0; i < [dataTypes count]; i++) {
        if ([string rangeOfString:[dataTypes objectAtIndex:i]].location != NSNotFound) {
            return i;
            break;
        }
    }
    return 0;
}

#pragma mark - Singleton methods

+ (DebugTypeTransformer *)sharedInstance
{
    static DebugTypeTransformer *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[DebugTypeTransformer alloc] init];
        
        // Do any other initialisation stuff here
    });
    return sharedInstance;
}

@end
