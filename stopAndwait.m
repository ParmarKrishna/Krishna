% CT111 Lab 1

% This program simulates the Stop and Wait ARQ at DLC Layer of a Digital
% Communication Link

% See Chapter 2 of Data Networks Book by Bertsekas and Gallager for a
% description of Stop and Wait ARQ

% This simulation is simplified with several assumptions as follows:

% 1. The delay experienced by the packets is a constant (in reality, it
% varies). Also, this delay is simulated only for the sender --> receiver
% link. The receiver --> sender link is assumed to be instantaneous. This
% is done to reduce the simulation complexity. In reality, the delay
% on s --> r link is roughly the same as the delay on r --> s link

% 2. The content of the packets is not important for this simulation of
% DLC layer ARQ protocol, i.e., the packets themselves are not simulated,
% only, the SN and the RN counts managed by the DLC are simulated

% 3. The communication channel introduces both the packet losses
% (erasures) as well as packet errors. The latter are typically detected at
% the DLC layer by a scheme called Cyclic Redundancy Checks or
% CRCs. We will not get into the CRC scheme in CT111. It is assumed here
% that the DLC is somehow (i.e., through the CRC) able to detect that a
% packet of binary digits has been received in error

% 4. The communication channel introduces the above errors in both the
% directions, i.e., on the s --> r link (on which the packets containing
% the SNs are transmitted) and also on the r --> s link (on which the ACKs
% containing the RNs are transmitted). This program models the errors
% only on the s --> r link. The r --> s link is assumed to be ideal.


clearvars % cleans up the Matlab workspace

%******** Define/configure the simulation variables ************

% The following variable defines the number of transmitted data packets

N = 10; % run experiments for different values of N

% (a programming note: the simulation may slow down as N is made larger)

% The following is required to initialize Matlab's memory. This is similar
% to C malloc() function or C++ "new" function.

% Will the program run if you do not do this memory initialization? Yes.
% However, it's not a good programming practice. Pre-allocating Matlab's
% memory improves the program execution

transmittedPacket = [0 -ones(1,1000*N-1)]; % allocate memory for a storing the transmit SN data
receivedPacket = -ones(1,100*N); % allocate memory where the RN data at the receiver is stored


% The following variable defines the packet erasure rate (probability of erasure)

pError = 0.2; % run experiments for different values of pError

% packet loss rate (probability of wrong reception)

pLoss = 0.4; % run experiments for different values of pLoss

% Following defines the one-way delay between the sender to the receiver
% (unit of time is arbitrary)
commChannelOneWaymaxDelay = 5;


% The sender needs to time out since the packets may be lost or the ACK
% messages containing the RNs may be lost. The following defines the
% time-out interval at the sender node. Typically it is set by the DLC layer
% as some scalar multiple of the one-way delay

timeOutInterval = 2*commChannelOneWaymaxDelay + 1;


%********* the main simulation starts now ***********

timeCount = 0; % the simulation runs for integer values of this timeCount
timeOutTimer = -timeOutInterval; % a timer needs to be initialized
SN = 0; % initialize the SN count at the sender
RN = 0; % initialize the RN count at the receiver

while SN <= N
    timeCount = timeCount + 1;
    commChannelOneWayDelay = randi([-2,5],1,1);
    % **********  the algorithm at the sender ***********
    % If the RN received from the receiver > the current value of SN
    % then increment SN and send the next packet with this SN toward the RN
    % Also start the timer
    
    if RN > SN
        SN = SN+1;
        transmittedPacket(timeCount) = SN;
        timeOutTimer = -timeOutInterval;
    end
    
    % If the timer expires (i.e., in this case timeOutTimer becomes greater
    % than zero), retransmit the same packet with the same SN
    
    if timeOutTimer>0
        transmittedPacket(timeCount) = SN;
        timeOutTimer = -timeOutInterval;
    end
    
    timeOutTimer = timeOutTimer+1;
    
    %*** the channel and the receiver simulation (packet erasures, packet errors) *******
    
    % the following if condition is necessary since the receiver starts
    % getting the packets only after one-way delay
    
    if timeCount>commChannelOneWayDelay
        
        % receivedPacket at this timeCount is the same as the
        % transmittedPacket at this timeCount minus the one-way delay
        
        receivedPacket(timeCount) = transmittedPacket(timeCount - commChannelOneWayDelay);
        
        if receivedPacket(timeCount) == -1 % -1 denotes that no packet arrived at the receiver at this timeCount
            continue % abort the following remaining simulation for this timeCount
        end
        
        % The simulation will reach this line only if the received packet
        % is not -1 (i.e., a packet is indeed received at the channel
        % output)
        
        % Does the packet get erased? Does it get lost? Use rand function
        % to simulate these impairments
        
        erasureEvent = rand < pLoss; % this binary variable is 1 with probability of pLoss
        errorEvent = rand < pError; % this binary variable is 1 with probability of pError
        
        if erasureEvent % if the erasure event occurs
            receivedPacket(timeCount) = -10; % erase the packet at the channel output
        end
        
        if errorEvent % if the error event has occured
            receivedPacket(timeCount) = -20; % corrupt the packet. Here, this is done by changing SN to one more than the largest value
        end
        
        % **********  the algorithm at the receiver ***********
        % If the SN of the received packet equals the RN maintained by the
        % receiver, increment the RN and send it back to the sender
        
        if receivedPacket(timeCount) == RN
            RN = RN+1;
        end
    end
end

transmittedPacket = transmittedPacket(1:timeCount);
receivedPacket = receivedPacket(1:timeCount);

%% ********* the simulation is completed. Plot the results ***********

close all;
%figure(1);
figure('units','normalized','outerposition',[0 0 1 1])
subplot(211); hold on;
pastPacket = -1;
for kk = 1:timeCount-1
    currentPacket = transmittedPacket(kk);
    if currentPacket == -1
        continue
    elseif currentPacket > pastPacket
        plotColor = 'b';
    else
        plotColor = [0.7 0.7 0.7]; % gray color
    end
    plotPacket(kk,plotColor,currentPacket);
    pastPacket = currentPacket;
end
title('Transmitted Packets (blue: new transmission; gray: repeated transmission)');

subplot(212); hold on;
for kk = 1:timeCount
    if receivedPacket(kk) == -1 % no packet received, do not plot
        continue
    elseif receivedPacket(kk) == -10 % packet got erased, plot in magenta, do not number it
        plotPacket(kk,'m',-99);
    elseif receivedPacket(kk) == -20 % packet in error, plot in red, do not number it
        plotPacket(kk,'r',-99);
    else % packet successfully received, plot in green, number its SN
        plotPacket(kk,[0 0.5 0],receivedPacket(kk));
    end
end
title('Received Packets (green: successfully received; red: received in error, magenta: got erased)');
xlabel('Time Epochs');