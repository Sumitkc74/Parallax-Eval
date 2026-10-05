"""
Worker Lifecycle Supervisor.
Provides state machine recovery for orphaned "zombie" RUNNING tasks on server startup,
and manages cooperative cancellation tokens (asyncio.Event) for active background experiments.
"""

import asyncio
from datetime import datetime, timezone
from typing import Dict, Optional
from sqlalchemy import select, update

from app.core.logging import logger
from app.models import Experiment


class WorkerSupervisor:
    """Singleton supervisor managing in-flight experiment lifecycle and cancellation."""

    def __init__(self):
        self._cancellation_events: Dict[str, asyncio.Event] = {}
        self._lock = asyncio.Lock()

    async def register_experiment(self, experiment_id: str) -> asyncio.Event:
        """Registers a newly running experiment and provides an asyncio cancellation token."""
        async with self._lock:
            event = asyncio.Event()
            self._cancellation_events[experiment_id] = event
            return event

    async def unregister_experiment(self, experiment_id: str) -> None:
        """Cleans up the cancellation token upon task completion or termination."""
        async with self._lock:
            self._cancellation_events.pop(experiment_id, None)

    async def request_cancellation(self, experiment_id: str) -> bool:
        """
        Signals cancellation to an active background experiment worker.
        Returns True if a running task was found and signalled, False otherwise.
        """
        async with self._lock:
            event = self._cancellation_events.get(experiment_id)
            if event:
                event.set()
                logger.info(f"Cancellation token set for experiment {experiment_id}")
                return True
            return False

    def is_cancelled(self, experiment_id: str) -> bool:
        """Checks if cancellation has been requested for the experiment."""
        event = self._cancellation_events.get(experiment_id)
        return event.is_set() if event is not None else False

    async def recover_zombie_experiments(self, session_factory) -> int:
        """
        Sweeps the database on application startup for experiments left in 'RUNNING' state
        due to previous worker process crash or server restart.
        Transitions them safely to 'FAILED' to prevent perpetual UI loading spinners.
        """
        logger.info("WorkerSupervisor: Checking for orphaned 'RUNNING' experiments...")
        recovered_count = 0
        now = datetime.now(timezone.utc)

        async with session_factory() as session:
            stmt = select(Experiment).where(Experiment.status == "RUNNING")
            result = await session.execute(stmt)
            zombies = result.scalars().all()

            if not zombies:
                logger.info("WorkerSupervisor: No zombie experiments found. Clean startup.")
                return 0

            for exp in zombies:
                exp.status = "FAILED"
                exp.error_message = "Worker process terminated unexpectedly; recovered by startup supervisor."
                exp.completed_at = now
                recovered_count += 1
                logger.warning(f"WorkerSupervisor: Recovered zombie experiment ID: {exp.id} ('{exp.name}')")

            await session.commit()

        logger.info(f"WorkerSupervisor: Cleaned up {recovered_count} zombie experiment(s).")
        return recovered_count


# Global supervisor singleton
supervisor = WorkerSupervisor()

