//
//  DebugTypeTransformer.h
//  dashPlayground
//
//  Created by NATTAPON AIEMLAOR on 27/6/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DebugTypeTransformer : NSObject

+(DebugTypeTransformer*)sharedInstance;

typedef NS_ENUM(uint16_t, DPMessageOriginatorClass) {
    DPMessageOriginatorClass_CreateNewBlock = 1,
    DPMessageOriginatorClass_ConnectBlock = 2,
    DPMessageOriginatorClass_DisconnectBlocks = 3,
    DPMessageOriginatorClass_CMasternodePayments = 4,
    DPMessageOriginatorClass_MASTERNODEPAYMENTSYNC = 5,
    DPMessageOriginatorClass_MASTERNODEPAYMENTVOTE = 6,
    DPMessageOriginatorClass_CMasternodePaymentVote = 7,
    DPMessageOriginatorClass_CMasternodeBlockPayees = 8,
    DPMessageOriginatorClass_CMasternodeMan = 9,
    DPMessageOriginatorClass_CMasternode = 10,
    DPMessageOriginatorClass_MasternodeMan = 11,
    DPMessageOriginatorClass_CGovernanceVoting = 12,
    DPMessageOriginatorClass_CGovernanceVote = 13,
    DPMessageOriginatorClass_MNGOVERNANCEOBJECT = 14,
    DPMessageOriginatorClass_CGovernanceManager = 15,
    DPMessageOriginatorClass_DSACCEPT = 16,
    DPMessageOriginatorClass_DSVIN = 17,
    DPMessageOriginatorClass_CPrivateSendServer = 18,
    DPMessageOriginatorClass_DSTX = 19,
    DPMessageOriginatorClass_TXLOCKREQUEST = 20,
    DPMessageOriginatorClass_CTxMemPool = 21,
    DPMessageOriginatorClass_CDarksendQueue = 22,
    DPMessageOriginatorClass_CDarksendBroadcastTx = 23,
    DPMessageOriginatorClass_CPrivateSend = 24,
    DPMessageOriginatorClass_DSQUEUE = 25,
    DPMessageOriginatorClass_DSSTATUSUPDATE = 26,
    DPMessageOriginatorClass_DSFINALTX = 27,
    DPMessageOriginatorClass_CPrivateSendClient = 28,
    DPMessageOriginatorClass_CompletedTransaction = 29,
    DPMessageOriginatorClass_AcceptConnection = 30,
    DPMessageOriginatorClass_ThreadSocketHandler = 31,
    DPMessageOriginatorClass_CNode = 32,
    DPMessageOriginatorClass_CGovernanceTriggerManager = 33,
    DPMessageOriginatorClass_CSuperblockManager = 34,
    DPMessageOriginatorClass_CSuperblock = 35,
    DPMessageOriginatorClass_CMasternodeSync = 36,
    DPMessageOriginatorClass_SYNCSTATUSCOUNT = 37,
    DPMessageOriginatorClass_CActiveDeterministicMasternodeManager = 38,
    DPMessageOriginatorClass_CActiveLegacyMasternodeManager = 39,
    DPMessageOriginatorClass_CActiveMasternode = 40,
    DPMessageOriginatorClass_CKeyHolderStorage = 41,
    DPMessageOriginatorClass_CGovernanceObject = 42,
    DPMessageOriginatorClass_CGovernance = 43,
    DPMessageOriginatorClass_CInstantSend = 44,
    DPMessageOriginatorClass_CTxLockVote = 45,
    DPMessageOriginatorClass_CSporkManager = 46,
    DPMessageOriginatorClass_CSporkMessage = 47,
    DPMessageOriginatorClass_CMasternodeBroadcast = 48,
    DPMessageOriginatorClass_CMasternodePing = 49,
    DPMessageOriginatorClass_CMessageHeader = 50,
};

- (NSMutableArray*)getAllDataTypes;
- (int)getDataTypeByString:(NSString*)string;

//typedef enum InstanceType {
//    InstanceType_Unknown = 0,
//    InstanceType_Manual = 1,
//    InstanceType_AWS = 2
//} InstanceType;
//
//@interface InstanceTypeTransformer : NSValueTransformer

@end
