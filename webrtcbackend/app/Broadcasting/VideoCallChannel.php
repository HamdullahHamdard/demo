<?php

namespace App\Broadcasting;

use App\Models\User;

class VideoCallChannel
{
    public function join(User $user, string $roomId): bool
    {
        return true;
    }
}
