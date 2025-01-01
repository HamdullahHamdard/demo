<?php

use Illuminate\Support\Facades\Broadcast;

Broadcast::channel('video-call.{roomId}', App\Broadcasting\VideoCallChannel::class);
